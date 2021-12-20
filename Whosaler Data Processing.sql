USE [DbSuperStore]
GO

/****** Object:  StoredProcedure [dbo].[uspProcess_Wholesale_Data]    Script Date: 20/12/2021 1:12:40 pm ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		NightWatch
-- Create date: 2021-12-17
-- Description:	Routine to process wholesale data from CSV
-- =============================================
CREATE PROCEDURE [dbo].[uspProcess_Wholesale_Data]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dbRawWholeSalesData]') AND type in (N'U'))
	DROP TABLE [dbo].dbRawWholeSalesData
	
	Create Table dbRawWholeSalesData
	( Channel int
	,Region int
	,Fresh bigint
	,Milk bigint
	,Grocery bigint
	,Frozen bigint
	,Detergents_Paper bigint
	,Delicassen bigint )



	BULK INSERT dbRawWholeSalesData
	FROM 'D:\Work Files\GECO Training\Training\WholeSales\Wholesale customers data.csv'
	WITH ( FORMAT='CSV',FirstRow =2 );

	Truncate Table Sales_Data
		
	Insert INTO Sales_Data
	SELECT Channel , Region , [Product Class] , Sales
	FROM
	(SELECT Channel,Region,Fresh,Milk,Grocery,Frozen,Detergents_Paper,Delicassen
	FROM dbRawWholeSalesData) p
	UNPIVOT
	(Sales FOR [Product Class] IN
	(Fresh,Milk,Grocery,Frozen,Detergents_Paper,Delicassen)
	)AS unpvt;

--  Create/Update look-up table for Region

	IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[lkpRegion]') AND type in (N'U'))
		create table lkpRegion ( ID int identity(1,1) , [Region] int , [Region_Description] nvarchar(25) )

	Truncate Table lkpRegion

	Insert Into lkpRegion (Region)
	Select distinct Region from Sales_Data

	Update lkpRegion set Region_Description = CHOOSE( [Region] , 'South' , 'East' , 'West' , 'North') 

--  Create/Update look-up table for Channel
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[lkpChannel]') AND type in (N'U'))
		create table lkpChannel ( ID int identity(1,1) , [Channel] int , [Channel_Description] nvarchar(25) )

	Truncate Table lkpChannel

	Insert Into lkpChannel ( Channel )
	Select distinct Channel from Sales_Data

	Update lkpChannel set Channel_Description = CHOOSE( [Channel] , 'TRADITIONAL' , 'MALL CHAINS' , 'MOM-AND-POPS') 


-- Create table for the final report file(s)
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[rptSales]') AND type in (N'U'))
		Create Table rptSales ( [Region] nvarchar(25) , [Channel] nvarchar(25) , [Product Class] nvarchar(25) , Sales Money )

	Truncate Table rptSales

	Insert Into RptSales
	Select B.Region_Description [Region] , 
		   C.Channel_Description [Channel] , 
		   A.[Product Class] ,
		   A.Sales 
		from Sales_Data A Left Outer Join
			lkpRegion B ON A.Region = B.Region Left Outer Join
			lkpChannel C ON A.Channel = C.Channel 


END


GO


