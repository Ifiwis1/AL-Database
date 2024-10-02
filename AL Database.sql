--**PART 1 ** --
--Create the database for Artificial lift clients
CREATE DATABASE ALDatabase;
--Switch to AL database
USE ALDatabase;
GO
--Create the different tables for the required entities
--Create table for the clients
CREATE TABLE Clients(
	clientID int NOT NULL PRIMARY KEY,
	clientName nvarchar(50) NOT NULL,
	clientotherName nvarchar(50) NULL,
	clientType nvarchar(20) NOT NULL,
	clientInputDate date NOT NULL,
	NoofField int NOT NULL
	);
INSERT INTO Clients
VALUES(1,'Shells','SPCC','IOC','2024-04-23',4), (2,'Ayip','NEOC','NOC','2023-06-21',6), (3,'Shells','SPCC','IOC','2024-04-23',2);
---If a patient's status becomes inactive, move the data to the Archive table.
--Create the Archive table for Inactive clients
CREATE TABLE ArchiveClients(
	AclientID int NOT NULL PRIMARY KEY,
	AclientName nvarchar(50) NOT NULL,
	AclientotherName nvarchar(50) NULL,
	AclientType nvarchar(20) NOT NULL,
	AclientInputDate date NOT NULL,
	ANoOfField int NOT NULL
	);


--Trigger to move the inactive clients to the archives
DROP TRIGGER IF EXISTS client_archive;
GO
CREATE TRIGGER client_archive
ON Clients
AFTER DELETE
AS 
BEGIN
	INSERT INTO ArchiveClients
	SELECT *
	FROM
	DELETED 
END;

--Create Field table
CREATE TABLE Field(
	FieldID int NOT NULL PRIMARY KEY,
	ClientID int NOT NULL FOREIGN KEY(ClientID) REFERENCES Clients(ClientID),
	FieldName nvarchar(50) NOT NULL,
	);
INSERT INTO Field
VALUES(1,1,'Isoko'), (2,1,'Agbada'), (3,1,'Ebocha');

--Create AL tech  table
CREATE TABLE ALTech(
	ALID int NOT NULL PRIMARY KEY,
	ALName nvarchar(50) NOT NULL);
---Inserting values into other tables
INSERT INTO ALTech
VALUES(1,'ESP'),(2,'GL'),(3,'PCP');

--Create Wells table
CREATE TABLE Wells(
	WellID int NOT NULL PRIMARY KEY,
	FieldID int NOT NULL FOREIGN KEY(FieldID) REFERENCES Field(FieldID),
	ALID int NOT NULL FOREIGN KEY(ALID) REFERENCES ALTech(ALID),
	ReservoirTemperature float NOT NULL,
	ReservoirPressure float NOT NULL,
	ProductivityIndex float NOT NULL,
	GasOilRatio float NOT NULL,
	CasingSize nvarchar(20) NOT NULL,
	ProposedCompletionDate date NULL
	);

INSERT INTO Wells
VALUES(1,1,1,79.0,3240.1,3.0,427,'9.625','2024-11-20'), (2,2,1,79.0,3240.1,3.0,427,'9.625','2024-12-20'), (3,1,2,79.0,3240.1,3.0,300,'9.625','2024-11-5'), (4,2,3,79.0,3240.1,3.5,0,'9.625','2024-10-20'); 

--View all created tables
SELECT *
FROM ArchiveClients;
SELECT *
FROM Clients;
SELECT *
FROM Field;
SELECT *
FROM Wells;
SELECT *
FROM ALTech;

--*******************************************************
--Add the constraint to check that the prop[osed completion date is not in the past at the point of entry
--This code is executed before inserting values into the wells table
--It ensures that the patients do not book appointments with date in the past.
ALTER TABLE Wells
ADD CONSTRAINT CPLDate CHECK (ProposedCompletionDate >= GETDATE());

--*******************************************************
--Search the database of the hospital for matching character strings by name of medicine.
--Sort with most recent medicine prescribed date first.
CREATE FUNCTION find_well_based_On_PI (@PI float)
	RETURNS TABLE
	AS
	RETURN
	(
		SELECT *
		FROM Wells
		WHERE ProductivityIndex >= @PI
	);

-- Search the hospital database for records with the medicine malarone
SELECT * 
FROM find_well_based_On_PI(3.0)
ORDER BY ReservoirPressure DESC;

--*******************************************************
--Update the details of a  well's reservoir pressure
--Show well's details before executing procedure
SELECT * 
FROM Wells
WHERE WellID = 1;

--Create the procedure to update well's details
CREATE PROCEDURE update_well @wellid int, @respressure float
AS
	SET NOCOUNT ON
	BEGIN TRANSACTION
	BEGIN TRY
		UPDATE Wells
		SET ReservoirPressure = @respressure
		WHERE WellID = @wellid
	COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
	ROLLBACK TRANSACTION
	SELECT ERROR_MESSAGE()
	END CATCH;

--Execute code
EXEC update_well @wellid = 1, @respressure = 1000;

--Show well's details after executing procedure
SELECT * 
FROM Wells
WHERE WellID = 1;



--*******************************************************
--Create the View for all the wells
CREATE VIEW Wells_details
AS
SELECT a.AppointmentID,a.AppointmentDate,do.DoctorID,do.DoctorFirstName, do.DoctorLastName, a.PatientID, de.DepartmentID,de.Specialty, pa.FeedbackDetails
FROM 
LEFT JOIN Wells AS w
ON a.DoctorID = do.DoctorID
LEFT JOIN Department AS de
ON do.DepartmentID = de.DepartmentID
--May not need this part
LEFT JOIN PastAppointment AS pa
ON a.AppointmentID = pa.AppointmentID

--Query the view to see the results
SELECT *
FROM Wells_details;


--*******************************************************
--Identify the number of completed wells with ESP

SELECT COUNT(*) AS NumberOfCompletedWells
FROM (
    SELECT w.*,a.*
    FROM Wells AS w INNER JOIN ALTech AS a
	ON w.ALID= a.ALID
    WHERE a.ALID = 'ESP'
) AS Wells;

--Return a table of the number of completed wells with ESP
SELECT w.*,a.*
FROM Wells AS w INNER JOIN ALTech AS a
ON w.ALID= a.ALID
WHERE a.ALID = 'ESP';

--*******************************************************


--The code below will be expanded once I expand the functionality of the database
--DATA INTEGRITY AND CONCURRENCY
---DATABASE SECURITY----
--*********************************************************************
---Database Back up and Recovery-----
--1)The database back up file was created.
--File Name: 
-- 2)Maintenance plan was created
--Code to clear the error for the maintenance plan wizard
SP_CONFIGURE 'SHOW ADVANCE',1
GO
RECONFIGURE WITH OVERRIDE
GO
SP_CONFIGURE 'AGENT XPs',1
GO
RECONFIGURE WITH OVERRIDE
GO

--Ensure successful restoration of the back up.
--Ensure the back up is not corrupted
BACKUP DATABASE ALDatabase
TO DISK ='C:\ADB Backup\ALDatabase_Full_Backup.bak'
WITH CHECKSUM

--Ensure that it can be restored
RESTORE VERIFYONLY
FROM DISK ='C:\ADB Backup\ALDatabase_Full_Backup.bak'
WITH CHECKSUM;

