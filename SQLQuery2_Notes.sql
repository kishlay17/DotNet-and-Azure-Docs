--CREATE DATABASE SUPPORT
USE SUPPORT
GO

Create table Employee(
emp_id int,
emp_name varchar(20)
)

alter table Employee alter column emp_id int NOT NULL
alter table Support..Employee add constraint PK_1 Primary KEY(emp_id)

insert into SUPPORT..Employee values (1,'kishlay')

Create Table EmployeeDetails(
id int primary key,
emp_address varchar(40),
emp_id int,
Constraint FK_id_emp_address Foreign Key(emp_id) references Employee(emp_id) on delete cascade
)
--or
alter table EmployeeDetails add Constraint FK_id_emp_address Foreign Key(emp_id) references Employee(emp_id)
on delete cascade
ON UPDATE NO ACTION  

insert into SUPPORT..EmployeeDetails values (2,'Pune',2)

select * from EmployeeDetails

drop table EmployeeDetails

--CREATE TABLE child_table
--(
--  column1 datatype [ NULL | NOT NULL ],
--  column2 datatype [ NULL | NOT NULL ],
--  ...

--  CONSTRAINT fk_name
--    FOREIGN KEY (child_col1, child_col2, ... child_col_n)
--    REFERENCES parent_table (parent_col1, parent_col2, ... parent_col_n)
--    ON DELETE CASCADE
--    [ ON UPDATE { NO ACTION | CASCADE | SET NULL | SET DEFAULT } ] 
--);

--The following constraints are commonly used in SQL:

	--NOT NULL - Ensures that a column cannot have a NULL value
	--UNIQUE - Ensures that all values in a column are different
	--PRIMARY KEY - A combination of a NOT NULL and UNIQUE. Uniquely identifies each row in a table
	--FOREIGN KEY - Uniquely identifies a row/record in another table
	--CHECK - Ensures that all values in a column satisfies a specific condition
	--DEFAULT - Sets a default value for a column when no value is specified
	--INDEX - Used to create and retrieve data from the database very quickly

select * into EMP from Employee where 1=2
drop table EMP

--It is not possible to rename a column using the ALTER TABLE statement in SQL Server. Use sp_rename instead.
ALTER TABLE EMP rename  column emp_id to Emp_id int

EXEC sp_RENAME 'TableName.OldColumnName' , 'NewColumnName', 'COLUMN'

--We can change the table name too with the same command.

 exec sp_RENAME 'Table_First', 'Table_Last'
--GO

select e.emp_id from Employee e
Left JOIN EmployeeDetails ed on e.emp_id = ed.emp_id

select getdate()

select CONVERT(varchar, GETDATE(), 101)

select DATEPART(dd, getdate())

select * from SysObjects where xtype='s'

select * from sys.objects WHERE name='Employee' AND TYPE IN (N'U')

Create function SplitString(@values varchar(max))
returns @emp taBLE
(
 id int
)
as BEGIN
insert into @emp
select emp_id from Employee
return
end

---drop function SplitString


CREATE FUNCTION abcd (@input VARCHAR(250))
RETURNS VARCHAR(250)
AS BEGIN
    RETURN 'xcj j'
END

-----Transaction-------

select * from Employee

declare @count int
set @count=@@ROWCOUNT
select @count

Begin Transaction
save tran sv1
insert into Employee values (2,'Kish')
save tran savepoint1;
delete from Employee where emp_id=2
save tran savepoint2;
rollback tran savepoint1
rollback


--sp_helpindex Employee

use adventureworks2012

SELECT * FROM HumanResources.Employee ORDER BY BusinessEntityID OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;



