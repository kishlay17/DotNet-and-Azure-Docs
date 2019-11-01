
-------SQL Code Snippets----------
-----------------------------------

---------While create table:
USE [Transaction] 
GO

SET ANSI_NULLS ON GO

SET QUOTED_IDENTIFIER ON GO

SET ANSI_PADDING ON Go

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'FolioOrder') AND TYPE IN (N'U'))
BEGIN
CREATE TABLE [dbo].[FolioOrder](
 [Id] [int] IDENTITY(1,1) NOT NULL,
 [RequestID] [varchar](50) NOT NULL,
 [CUSIP] [char](12) NULL,
 [Quantity] [decimal](20, 5) NULL,
 [Amount] [money] NULL, 
 [OrderReceiptDateTime] [datetime] NULL, 
 CONSTRAINT [PK_FolioOrder] PRIMARY KEY CLUSTERED ( [Id] ASC )
) END

CREATE TABLE [dbo].[FolioAllocations]( 
 [AllocationID] INT not null IDENTITY(1,1),
 [BlockID] INT not NULL, 
 [AccountNo] CHAR(8) not NULL, 
 CONSTRAINT [PK_FolioAllocations] PRIMARY KEY NONCLUSTERED ([AllocationID] ASC), 
 CONSTRAINT [U_BlockID_AccountNo] UNIQUE(BlockID, AccountNo)
 )

------Create table Type:

CREATE TYPE [dbo].[UDT_FolioOrderAuditList] AS TABLE(
 [Id] [int] NULL 
 )
 

--------------
DECLARE @BlockAccountNo varchar(10)
SET @BlockAccountNo = '00005027'
SELECT @BlockAccountNo= IsNull(ConfigValue, @BlockAccountNo) FROM [Support].[dbo].[TPDAdminConfiguration] WITH (NOLOCK) WHERE ConfigName ='FolioBlockAccountNo' AND Category='EnhancedTRading'
 
---Create teporary table------
CREATE TABLE #results( 
 Id int NULL, 
 AllocationID int NULL ) 
 
------create temp table variable-----
declare @AdditionalInfo table (AllocationID int,AdditionalInfoTE text,AdditionalInfoTEH text)
INSERT INTO @AdditionalInfo
Select...

 
--------ALTER TABLE: and rename SP - - 

IF EXISTS(SELECT * FROM sys.columns WHERE [name] = N'EOOrderID' AND [object_id] = OBJECT_ID(N'FolioAllocations')) 
BEGIN 
 ALTER TABLE [dbo].[FolioAllocations] ALTER COLUMN EOOrderID int NULL 
END

IF EXISTS(SELECT TOP 1 1 FROM sys.columns WHERE [name] = N'OrderID' AND [object_id] = OBJECT_ID(N'FolioAllocations_Audit')) 
BEGIN 
 EXEC sp_rename 'FolioAllocations_Audit.OrderID', 'VendorOrderID', 'COLUMN'
END


--------CREATE STORED PROCEDURES:

USE [Transaction]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Folio_GetOrderDetailsByIds]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Folio_GetOrderDetailsByIds]
GO
SET ANSI_NULLS ON GO
SET QUOTED_IDENTIFIER ON GO

CREATE PROCEDURE [dbo].[Folio_GetOrderDetailsByIds]
 @OrderIds varchar(max),
 @FolioOrderAuditList AS [dbo].[UDT_FolioOrderAuditList] READONLY - -[UDT_FolioOrderAuditList] is a type of table
AS
BEGIN
 SET NOCOUNT ON 
 create table #Orders (OrderID int primary key)
 
 insert into #Orders (OrderID) 
 SELECT distinct IsNull(y.i.value('(./text())[1]', 'int'),'')
 FROM ( 
 SELECT x = CONVERT(XML, '<i>' + REPLACE(@OrderIds, ',', '</i><i>') + '</i>').query('.') 
 ) AS a CROSS APPLY x.nodes('i') AS y(i)

SELECT 
 F.Id,
 RequestID, 
 FROM
dbo.FolioOrder (nolock) F
INNER JOIN #Orders ord ON F.VendorOrderID = ord.OrderID AND ISNULL(BlockID,0) = 0
WHERE F.OrderStatus <> 'R' AND SecurityType <> 'MF'
UNION ALL 
 
SELECT 
 F.Id,
 RequestID,
 GETDATE() as [UpdatedDateTime] 
FROM
dbo.FolioOrder (nolock) F
INNER JOIN #BlockOrders ord ON F.BlockID = ord.OrderID AND ISNULL(BlockID,0) <> 0 
WHERE F.OrderStatus <> 'R' AND SecurityType <> 'MF'

IF OBJECT_ID('tempdb.dbo.#Orders', 'U') IS NOT NULL DROP TABLE #Orders
END
GO


-----Outer Query can be referenced in Inner querties...Co-Related Query-------
SELECT AllocationID 
 ,(SELECT TOP 1 te.AdditionalInfo FROM [Transaction]..CWT_TradingLog te (nolock) WHERE te.AccountNo=fa..AccountNo 
 and te.Request like '%' + cast(fa.VendorOrderID as varchar(20)) + '%' 
 and te.Request like '%' + fo.Symbol + '%' 
 Order by TimeStamp desc) AdditionalInfoTE 
 
 FROM [Transaction].dbo.FolioAllocations fa (nolock)
 inner join [Transaction].dbo.FolioOrder fo (nolock) on fa.BlockID=fo.BlockID and fo.OrderStatus <> 'R'
 where fa.EOOrderID=@EquityOptionOrderId 
 order by fa.AccountNo

----------------
CASE WHEN [LimitPrice] = 0 THEN NULL ELSE [LimitPrice] END
case when fa.Status in ('A','R') then fa.ApproverComments else Coalesce(ai.AdditionalInfoTE,ai.AdditionalInfoTEH) end as [ApproverComments]

----------------
UPDATE [FolioOrder] SET [OrderStatus]= 'R' WHERE [BlockID] IN (SELECT [BlockID] FROM @batch_FolioOrders WHERE [BlockID]>0)


-------Group with BlockID and take first record
WITH groups AS (
 SELECT 
 [RequestID], 
 [Amount], 
 ROW_NUMBER() OVER(PARTITION BY BlockID ORDER BY BlockID DESC) AS rk
 FROM @batch_FolioOrders WHERE [BlockID] > 0)

INSERT INTO [Transaction].[DBO].[FolioOrder] (
 [RequestID], 
 [Amount] )
 SELECT [RequestID], 
 [Amount] FROM groups WHERE groups.rk = 1
 
 

---------CTE - common table expression

with groups as(
select Top 10 symbol, SUM(Amount) amo from [Transaction].[dbo].[FolioOrder] 
group by Symbol)

select * from groups

----------
with groups (Symbol, Amount) as(
select top 10 symbol, SUM(Amount) from [Transaction].[dbo].[FolioOrder] 
group by Symbol)

select * from groups

----------
with groups (Symbol, Amount) as(
select top 10 symbol, SUM(Amount) from [Transaction].[dbo].[FolioOrder] 
group by Symbol order by symbol
UNION ALL
select top 10 symbol, SUM(Amount) from [Transaction].[dbo].[FolioOrder] 
group by Symbol order by symbol desc)

select * from groups


------Bulk Update in Table :

update  Table1
set Description = t2.Description, Summary= t2.Summary
from Table1 t1
inner join Table2 t2 on t1.DescriptionID = t2.ID


-----------

--You can use GROUP BY SalesOrderID. The difference is, with GROUP BY you can only have the aggregated values for the columns that 
--are not included in GROUP BY.

--In contrast, using windowed aggregate functions instead of GROUP BY, you can retrieve both aggregated and non-aggregated values. 
--That is, although you are not doing that in your example query, you could retrieve both 
--individual OrderQty values and their sums, counts, averages etc. over groups of same SalesOrderIDs.

select SalesOrderID, SpecialOfferID, sum(OrderQty) from Sales.SalesOrderDetail group by SalesOrderID

select SalesOrderID, SpecialOfferID, sum(OrderQty) over(partition by salesOrderId) as 'Total' from Sales.SalesOrderDetail


;with groups AS(
select SalesOrderID, SpecialOfferID, ROW_NUMBER() OVER(Partition by SalesOrderID order by salesorderid) as rk 
from Sales.SalesOrderDetail
)
select * from groups where groups.rk=1


----------------Pagination------------

SELECT * FROM HumanResources.Employee ORDER BY BusinessEntityID OFFSET  S FETCH NEXT 10 ROWS ONLY;



























