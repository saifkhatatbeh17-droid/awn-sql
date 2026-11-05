-- Generated from immutable migrations. Entire empty installation and ledger are atomic.
-- Use the migration runner to upgrade an existing database.
USE [Awn];
GO
SET ANSI_NULLS ON;SET QUOTED_IDENTIFIER ON;SET ANSI_PADDING ON;SET ANSI_WARNINGS ON;
SET ARITHABORT ON;SET CONCAT_NULL_YIELDS_NULL ON;SET NUMERIC_ROUNDABORT OFF;SET XACT_ABORT ON;
DECLARE @ExpectedDatabase sysname=N'Awn';
IF DB_NAME()<>@ExpectedDatabase THROW 52568,'Select the expected empty database.',1;
IF EXISTS(SELECT 1 FROM sys.tables WHERE is_ms_shipped=0) THROW 52569,'Installer requires an empty database; use migrations for upgrades.',1;
BEGIN TRY
 BEGIN TRANSACTION;
 EXEC sys.sp_executesql N'IF SCHEMA_ID(N''core'') IS NULL EXEC(N''CREATE SCHEMA core AUTHORIZATION dbo'');';
 EXEC sys.sp_executesql N'CREATE TABLE core.SchemaMigration(Version int NOT NULL CONSTRAINT PK_SchemaMigration PRIMARY KEY,FileName nvarchar(180) NOT NULL,FileHash binary(32) NOT NULL,AppliedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_SchemaMigration_Applied DEFAULT SYSUTCDATETIME(),ApplicationMode varchar(12) NOT NULL CONSTRAINT CK_SchemaMigration_Mode CHECK(ApplicationMode IN (''executed'',''adopted'')));';
 -- BEGIN 001_core_identity.sql
 EXEC sys.sp_executesql N'SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;';
 EXEC sys.sp_executesql N'
/* Awn database baseline. Apply to an explicitly selected empty SQL Server database. */
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF SCHEMA_ID(N''core'') IS NULL EXEC(N''CREATE SCHEMA core AUTHORIZATION dbo'');
IF SCHEMA_ID(N''security'') IS NULL EXEC(N''CREATE SCHEMA security AUTHORIZATION dbo'');
IF SCHEMA_ID(N''audit'') IS NULL EXEC(N''CREATE SCHEMA audit AUTHORIZATION dbo'');
IF SCHEMA_ID(N''people'') IS NULL EXEC(N''CREATE SCHEMA people AUTHORIZATION dbo'');

BEGIN TRY
  

  CREATE TABLE core.Organization (
    OrganizationId uniqueidentifier NOT NULL CONSTRAINT DF_Organization_Id DEFAULT NEWSEQUENTIALID(),
    Code nvarchar(40) NOT NULL,
    Name nvarchar(200) NOT NULL,
    CountryCode char(2) NOT NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_Organization_Status DEFAULT (''active''),
    CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_Organization_Created DEFAULT SYSUTCDATETIME(),
    RowVersion rowversion NOT NULL,
    CONSTRAINT PK_Organization PRIMARY KEY CLUSTERED (OrganizationId),
    CONSTRAINT UQ_Organization_Code UNIQUE (Code),
    CONSTRAINT CK_Organization_Status CHECK (Status IN (''active'',''suspended'',''closed'')),
    CONSTRAINT CK_Organization_Country CHECK (CountryCode LIKE ''[A-Z][A-Z]'')
  );

  CREATE TABLE core.School (
    SchoolId uniqueidentifier NOT NULL CONSTRAINT DF_School_Id DEFAULT NEWSEQUENTIALID(),
    OrganizationId uniqueidentifier NOT NULL,
    Code nvarchar(40) NOT NULL,
    Name nvarchar(200) NOT NULL,
    TimeZoneId nvarchar(100) NOT NULL,
    DefaultCulture nvarchar(20) NOT NULL CONSTRAINT DF_School_Culture DEFAULT (N''ar-JO''),
    Status varchar(20) NOT NULL CONSTRAINT DF_School_Status DEFAULT (''active''),
    CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_School_Created DEFAULT SYSUTCDATETIME(),
    RowVersion rowversion NOT NULL,
    CONSTRAINT PK_School PRIMARY KEY CLUSTERED (SchoolId),
    CONSTRAINT UQ_School_OrgCode UNIQUE (OrganizationId, Code),
    CONSTRAINT UQ_School_OrgId UNIQUE (OrganizationId, SchoolId),
    CONSTRAINT FK_School_Organization FOREIGN KEY (OrganizationId) REFERENCES core.Organization(OrganizationId),
    CONSTRAINT CK_School_Status CHECK (Status IN (''active'',''suspended'',''closed''))
  );

  CREATE TABLE core.SchoolYear (
    SchoolYearId uniqueidentifier NOT NULL CONSTRAINT DF_SchoolYear_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    Code nvarchar(20) NOT NULL,
    Name nvarchar(100) NOT NULL,
    StartDate date NOT NULL,
    EndDate date NOT NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_SchoolYear_Status DEFAULT (''planned''),
    CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_SchoolYear_Created DEFAULT SYSUTCDATETIME(),
    RowVersion rowversion NOT NULL,
    CONSTRAINT PK_SchoolYear PRIMARY KEY CLUSTERED (SchoolYearId),
    CONSTRAINT UQ_SchoolYear_SchoolCode UNIQUE (SchoolId, Code),
    CONSTRAINT UQ_SchoolYear_SchoolId UNIQUE (SchoolId, SchoolYearId),
    CONSTRAINT FK_SchoolYear_School FOREIGN KEY (SchoolId) REFERENCES core.School(SchoolId),
    CONSTRAINT CK_SchoolYear_Dates CHECK (StartDate <= EndDate),
    CONSTRAINT CK_SchoolYear_Status CHECK (Status IN (''planned'',''active'',''closed'',''archived''))
  );

  CREATE TABLE core.AcademicTerm (
    TermId uniqueidentifier NOT NULL CONSTRAINT DF_AcademicTerm_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    SchoolYearId uniqueidentifier NOT NULL,
    Code nvarchar(30) NOT NULL,
    Name nvarchar(100) NOT NULL,
    SequenceNo smallint NOT NULL,
    StartDate date NOT NULL,
    EndDate date NOT NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_AcademicTerm_Status DEFAULT (''planned''),
    RowVersion rowversion NOT NULL,
    CONSTRAINT PK_AcademicTerm PRIMARY KEY CLUSTERED (TermId),
    CONSTRAINT UQ_AcademicTerm_Sequence UNIQUE (SchoolId, SchoolYearId, SequenceNo),
    CONSTRAINT UQ_AcademicTerm_Scope UNIQUE (SchoolId, SchoolYearId, TermId),
    CONSTRAINT FK_AcademicTerm_Year FOREIGN KEY (SchoolId, SchoolYearId) REFERENCES core.SchoolYear(SchoolId, SchoolYearId),
    CONSTRAINT CK_AcademicTerm_Sequence CHECK (SequenceNo > 0),
    CONSTRAINT CK_AcademicTerm_Dates CHECK (StartDate <= EndDate),
    CONSTRAINT CK_AcademicTerm_Status CHECK (Status IN (''planned'',''active'',''closed'',''archived''))
  );

  CREATE TABLE people.Person (
    PersonId uniqueidentifier NOT NULL CONSTRAINT DF_Person_Id DEFAULT NEWSEQUENTIALID(),
    GivenName nvarchar(100) NOT NULL,
    MiddleName nvarchar(100) NULL,
    FamilyName nvarchar(100) NOT NULL,
    PreferredName nvarchar(150) NULL,
    DateOfBirth date NULL,
    PrimaryEmail nvarchar(254) NULL,
    PrimaryPhone nvarchar(40) NULL,
    PreferredCulture nvarchar(20) NOT NULL CONSTRAINT DF_Person_Culture DEFAULT (N''ar''),
    CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_Person_Created DEFAULT SYSUTCDATETIME(),
    RowVersion rowversion NOT NULL,
    CONSTRAINT PK_Person PRIMARY KEY CLUSTERED (PersonId),
    CONSTRAINT CK_Person_Email CHECK (PrimaryEmail IS NULL OR PrimaryEmail NOT LIKE N''% %''),
    CONSTRAINT CK_Person_Dob CHECK (DateOfBirth IS NULL OR DateOfBirth <= CONVERT(date, SYSUTCDATETIME()))
  );

  CREATE TABLE security.UserAccount (
    UserId uniqueidentifier NOT NULL CONSTRAINT DF_UserAccount_Id DEFAULT NEWSEQUENTIALID(),
    PersonId uniqueidentifier NULL,
    Username nvarchar(120) NOT NULL,
    NormalizedUsername nvarchar(120) NOT NULL,
    CredentialHash nvarchar(500) NULL,
    CredentialScheme nvarchar(80) NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_UserAccount_Status DEFAULT (''pending''),
    FailedSignInCount int NOT NULL CONSTRAINT DF_UserAccount_Failed DEFAULT (0),
    LockedUntilUtc datetime2(3) NULL,
    LastSignInAtUtc datetime2(3) NULL,
    CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_UserAccount_Created DEFAULT SYSUTCDATETIME(),
    RowVersion rowversion NOT NULL,
    CONSTRAINT PK_UserAccount PRIMARY KEY CLUSTERED (UserId),
    CONSTRAINT UQ_UserAccount_NormalizedUsername UNIQUE (NormalizedUsername),
    CONSTRAINT FK_UserAccount_Person FOREIGN KEY (PersonId) REFERENCES people.Person(PersonId),
    CONSTRAINT CK_UserAccount_Status CHECK (Status IN (''pending'',''active'',''locked'',''disabled'',''closed'')),
    CONSTRAINT CK_UserAccount_FailedCount CHECK (FailedSignInCount >= 0),
    CONSTRAINT CK_UserAccount_Credential CHECK ((CredentialHash IS NULL AND CredentialScheme IS NULL) OR (CredentialHash IS NOT NULL AND CredentialScheme IS NOT NULL))
  );

  CREATE TABLE security.Role (
    RoleId smallint IDENTITY(1,1) NOT NULL,
    Code varchar(60) NOT NULL,
    Name nvarchar(120) NOT NULL,
    IsSystemRole bit NOT NULL CONSTRAINT DF_Role_System DEFAULT (0),
    CONSTRAINT PK_Role PRIMARY KEY (RoleId),
    CONSTRAINT UQ_Role_Code UNIQUE (Code)
  );

  CREATE TABLE security.Permission (
    PermissionId int IDENTITY(1,1) NOT NULL,
    Code varchar(120) NOT NULL,
    Description nvarchar(300) NOT NULL,
    CONSTRAINT PK_Permission PRIMARY KEY (PermissionId),
    CONSTRAINT UQ_Permission_Code UNIQUE (Code)
  );

  CREATE TABLE security.RolePermission (
    RoleId smallint NOT NULL,
    PermissionId int NOT NULL,
    CONSTRAINT PK_RolePermission PRIMARY KEY (RoleId, PermissionId),
    CONSTRAINT FK_RolePermission_Role FOREIGN KEY (RoleId) REFERENCES security.Role(RoleId),
    CONSTRAINT FK_RolePermission_Permission FOREIGN KEY (PermissionId) REFERENCES security.Permission(PermissionId)
  );

  CREATE TABLE security.SchoolMembership (
    MembershipId uniqueidentifier NOT NULL CONSTRAINT DF_SchoolMembership_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    UserId uniqueidentifier NOT NULL,
    MemberType varchar(30) NOT NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_SchoolMembership_Status DEFAULT (''active''),
    ValidFrom date NOT NULL CONSTRAINT DF_SchoolMembership_From DEFAULT (CONVERT(date, SYSUTCDATETIME())),
    ValidTo date NULL,
    CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_SchoolMembership_Created DEFAULT SYSUTCDATETIME(),
    RowVersion rowversion NOT NULL,
    CONSTRAINT PK_SchoolMembership PRIMARY KEY CLUSTERED (MembershipId),
    CONSTRAINT UQ_SchoolMembership_Scope UNIQUE (SchoolId, MembershipId),
    CONSTRAINT UQ_SchoolMembership_User UNIQUE (SchoolId, UserId, MemberType, ValidFrom),
    CONSTRAINT FK_SchoolMembership_School FOREIGN KEY (SchoolId) REFERENCES core.School(SchoolId),
    CONSTRAINT FK_SchoolMembership_User FOREIGN KEY (UserId) REFERENCES security.UserAccount(UserId),
    CONSTRAINT CK_SchoolMembership_Dates CHECK (ValidTo IS NULL OR ValidFrom <= ValidTo),
    CONSTRAINT CK_SchoolMembership_Status CHECK (Status IN (''active'',''suspended'',''ended''))
  );

  CREATE TABLE security.UserRole (
    UserRoleId uniqueidentifier NOT NULL CONSTRAINT DF_UserRole_Id DEFAULT NEWSEQUENTIALID(),
    UserId uniqueidentifier NOT NULL,
    RoleId smallint NOT NULL,
    OrganizationId uniqueidentifier NULL,
    SchoolId uniqueidentifier NULL,
    ValidFrom datetime2(3) NOT NULL CONSTRAINT DF_UserRole_From DEFAULT SYSUTCDATETIME(),
    ValidTo datetime2(3) NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_UserRole_Status DEFAULT (''active''),
    GrantedByUserId uniqueidentifier NULL,
    CONSTRAINT PK_UserRole PRIMARY KEY CLUSTERED (UserRoleId),
    CONSTRAINT UQ_UserRole_Scope UNIQUE (UserId, RoleId, OrganizationId, SchoolId, ValidFrom),
    CONSTRAINT FK_UserRole_User FOREIGN KEY (UserId) REFERENCES security.UserAccount(UserId),
    CONSTRAINT FK_UserRole_Role FOREIGN KEY (RoleId) REFERENCES security.Role(RoleId),
    CONSTRAINT FK_UserRole_Organization FOREIGN KEY (OrganizationId) REFERENCES core.Organization(OrganizationId),
    CONSTRAINT FK_UserRole_School FOREIGN KEY (OrganizationId, SchoolId) REFERENCES core.School(OrganizationId, SchoolId),
    CONSTRAINT FK_UserRole_GrantedBy FOREIGN KEY (GrantedByUserId) REFERENCES security.UserAccount(UserId),
    CONSTRAINT CK_UserRole_Scope CHECK (OrganizationId IS NOT NULL OR SchoolId IS NULL),
    CONSTRAINT CK_UserRole_Dates CHECK (ValidTo IS NULL OR ValidFrom < ValidTo),
    CONSTRAINT CK_UserRole_Status CHECK (Status IN (''active'',''revoked'',''expired''))
  );

  CREATE TABLE security.RolePermissionScope (
    UserRoleId uniqueidentifier NOT NULL,
    PermissionId int NOT NULL,
    Effect varchar(8) NOT NULL,
    Reason nvarchar(500) NOT NULL,
    ValidFrom datetime2(3) NOT NULL,
    ValidTo datetime2(3) NULL,
    GrantedByUserId uniqueidentifier NOT NULL,
    CONSTRAINT PK_RolePermissionScope PRIMARY KEY (UserRoleId, PermissionId, ValidFrom),
    CONSTRAINT FK_RolePermissionScope_UserRole FOREIGN KEY (UserRoleId) REFERENCES security.UserRole(UserRoleId),
    CONSTRAINT FK_RolePermissionScope_Permission FOREIGN KEY (PermissionId) REFERENCES security.Permission(PermissionId),
    CONSTRAINT FK_RolePermissionScope_Grantor FOREIGN KEY (GrantedByUserId) REFERENCES security.UserAccount(UserId),
    CONSTRAINT CK_RolePermissionScope_Effect CHECK (Effect IN (''allow'',''deny'')),
    CONSTRAINT CK_RolePermissionScope_Dates CHECK (ValidTo IS NULL OR ValidFrom < ValidTo)
  );

  CREATE TABLE audit.AuditEvent (
    AuditEventId bigint IDENTITY(1,1) NOT NULL,
    OrganizationId uniqueidentifier NULL,
    SchoolId uniqueidentifier NULL,
    ActorUserId uniqueidentifier NULL,
    ActionCode varchar(100) NOT NULL,
    EntityType varchar(120) NOT NULL,
    EntityId nvarchar(100) NULL,
    OccurredAtUtc datetime2(3) NOT NULL CONSTRAINT DF_AuditEvent_Occurred DEFAULT SYSUTCDATETIME(),
    CorrelationId uniqueidentifier NULL,
    Outcome varchar(20) NOT NULL,
    MetadataJson nvarchar(max) NULL,
    CONSTRAINT PK_AuditEvent PRIMARY KEY CLUSTERED (AuditEventId),
    CONSTRAINT FK_AuditEvent_Organization FOREIGN KEY (OrganizationId) REFERENCES core.Organization(OrganizationId),
    CONSTRAINT FK_AuditEvent_SchoolScope FOREIGN KEY (OrganizationId, SchoolId) REFERENCES core.School(OrganizationId, SchoolId),
    CONSTRAINT FK_AuditEvent_Actor FOREIGN KEY (ActorUserId) REFERENCES security.UserAccount(UserId),
    CONSTRAINT CK_AuditEvent_Outcome CHECK (Outcome IN (''success'',''failure'',''denied'')),
    CONSTRAINT CK_AuditEvent_Json CHECK (MetadataJson IS NULL OR ISJSON(MetadataJson)=1)
  );

  CREATE INDEX IX_School_Organization_Status ON core.School(OrganizationId, Status);
  CREATE INDEX IX_SchoolYear_School_Dates ON core.SchoolYear(SchoolId, StartDate, EndDate);
  CREATE INDEX IX_UserRole_User_Status_Validity ON security.UserRole(UserId, Status, ValidFrom, ValidTo);
  CREATE INDEX IX_Membership_User_Status ON security.SchoolMembership(UserId, Status, SchoolId);
  CREATE INDEX IX_AuditEvent_School_Time ON audit.AuditEvent(SchoolId, OccurredAtUtc DESC) INCLUDE (ActorUserId, ActionCode, EntityType, Outcome);
  CREATE INDEX IX_AuditEvent_Actor_Time ON audit.AuditEvent(ActorUserId, OccurredAtUtc DESC) WHERE ActorUserId IS NOT NULL;

  
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
  THROW;
END CATCH;
';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(1,N''001_core_identity.sql'',0x62bef398f37e2ae5602697ac21fa3706ea806482d68babe5dad1b4215c9e0379,''executed'');';
 -- BEGIN 002_academic_structure.sql
 EXEC sys.sp_executesql N'SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;';
 EXEC sys.sp_executesql N'
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY
  
  IF SCHEMA_ID(N''academic'') IS NULL EXEC(N''CREATE SCHEMA academic AUTHORIZATION dbo'');
  IF SCHEMA_ID(N''people'') IS NULL EXEC(N''CREATE SCHEMA people AUTHORIZATION dbo'');

  CREATE TABLE academic.Stage (
    StageId uniqueidentifier NOT NULL CONSTRAINT DF_Stage_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    Code nvarchar(40) NOT NULL,
    Name nvarchar(120) NOT NULL,
    SortOrder smallint NOT NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_Stage_Status DEFAULT (''active''),
    RowVersion rowversion NOT NULL,
    CONSTRAINT PK_Stage PRIMARY KEY CLUSTERED (StageId),
    CONSTRAINT UQ_Stage_ScopeCode UNIQUE (SchoolId, Code),
    CONSTRAINT UQ_Stage_ScopeId UNIQUE (SchoolId, StageId),
    CONSTRAINT FK_Stage_School FOREIGN KEY (SchoolId) REFERENCES core.School(SchoolId),
    CONSTRAINT CK_Stage_Sort CHECK (SortOrder >= 0),
    CONSTRAINT CK_Stage_Status CHECK (Status IN (''active'',''inactive'',''archived''))
  );

  CREATE TABLE academic.GradeLevel (
    GradeLevelId uniqueidentifier NOT NULL CONSTRAINT DF_GradeLevel_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    StageId uniqueidentifier NOT NULL,
    Code nvarchar(40) NOT NULL,
    Name nvarchar(120) NOT NULL,
    SortOrder smallint NOT NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_GradeLevel_Status DEFAULT (''active''),
    RowVersion rowversion NOT NULL,
    CONSTRAINT PK_GradeLevel PRIMARY KEY CLUSTERED (GradeLevelId),
    CONSTRAINT UQ_GradeLevel_ScopeCode UNIQUE (SchoolId, Code),
    CONSTRAINT UQ_GradeLevel_ScopeId UNIQUE (SchoolId, GradeLevelId),
    CONSTRAINT FK_GradeLevel_Stage FOREIGN KEY (SchoolId, StageId) REFERENCES academic.Stage(SchoolId, StageId),
    CONSTRAINT FK_GradeLevel_School FOREIGN KEY (SchoolId) REFERENCES core.School(SchoolId),
    CONSTRAINT CK_GradeLevel_Sort CHECK (SortOrder >= 0),
    CONSTRAINT CK_GradeLevel_Status CHECK (Status IN (''active'',''inactive'',''archived''))
  );

  CREATE TABLE academic.ClassSection (
    ClassSectionId uniqueidentifier NOT NULL CONSTRAINT DF_ClassSection_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    SchoolYearId uniqueidentifier NOT NULL,
    GradeLevelId uniqueidentifier NOT NULL,
    Code nvarchar(40) NOT NULL,
    Name nvarchar(120) NOT NULL,
    Capacity smallint NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_ClassSection_Status DEFAULT (''active''),
    RowVersion rowversion NOT NULL,
    CONSTRAINT PK_ClassSection PRIMARY KEY CLUSTERED (ClassSectionId),
    CONSTRAINT UQ_ClassSection_ScopeCode UNIQUE (SchoolId, SchoolYearId, Code),
    CONSTRAINT UQ_ClassSection_ScopeId UNIQUE (SchoolId, SchoolYearId, ClassSectionId),
    CONSTRAINT UQ_ClassSection_SchoolId UNIQUE (SchoolId, ClassSectionId),
    CONSTRAINT FK_ClassSection_Year FOREIGN KEY (SchoolId, SchoolYearId) REFERENCES core.SchoolYear(SchoolId, SchoolYearId),
    CONSTRAINT FK_ClassSection_Grade FOREIGN KEY (SchoolId, GradeLevelId) REFERENCES academic.GradeLevel(SchoolId, GradeLevelId),
    CONSTRAINT CK_ClassSection_Capacity CHECK (Capacity IS NULL OR Capacity > 0),
    CONSTRAINT CK_ClassSection_Status CHECK (Status IN (''active'',''inactive'',''closed'',''archived''))
  );

  CREATE TABLE academic.Subject (
    SubjectId uniqueidentifier NOT NULL CONSTRAINT DF_Subject_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    StageId uniqueidentifier NULL,
    Code nvarchar(40) NOT NULL,
    Name nvarchar(160) NOT NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_Subject_Status DEFAULT (''active''),
    RowVersion rowversion NOT NULL,
    CONSTRAINT PK_Subject PRIMARY KEY CLUSTERED (SubjectId),
    CONSTRAINT UQ_Subject_ScopeCode UNIQUE (SchoolId, Code),
    CONSTRAINT UQ_Subject_ScopeId UNIQUE (SchoolId, SubjectId),
    CONSTRAINT FK_Subject_School FOREIGN KEY (SchoolId) REFERENCES core.School(SchoolId),
    CONSTRAINT FK_Subject_Stage FOREIGN KEY (SchoolId, StageId) REFERENCES academic.Stage(SchoolId, StageId),
    CONSTRAINT CK_Subject_Status CHECK (Status IN (''active'',''inactive'',''archived''))
  );

  CREATE TABLE academic.Building (
    BuildingId uniqueidentifier NOT NULL CONSTRAINT DF_Building_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    Code nvarchar(40) NOT NULL,
    Name nvarchar(120) NOT NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_Building_Status DEFAULT (''active''),
    CONSTRAINT PK_Building PRIMARY KEY CLUSTERED (BuildingId),
    CONSTRAINT UQ_Building_ScopeCode UNIQUE (SchoolId, Code),
    CONSTRAINT UQ_Building_ScopeId UNIQUE (SchoolId, BuildingId),
    CONSTRAINT FK_Building_School FOREIGN KEY (SchoolId) REFERENCES core.School(SchoolId),
    CONSTRAINT CK_Building_Status CHECK (Status IN (''active'',''inactive'',''archived''))
  );

  CREATE TABLE academic.Room (
    RoomId uniqueidentifier NOT NULL CONSTRAINT DF_Room_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    BuildingId uniqueidentifier NULL,
    Code nvarchar(40) NOT NULL,
    Name nvarchar(120) NOT NULL,
    Capacity smallint NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_Room_Status DEFAULT (''active''),
    CONSTRAINT PK_Room PRIMARY KEY CLUSTERED (RoomId),
    CONSTRAINT UQ_Room_ScopeCode UNIQUE (SchoolId, Code),
    CONSTRAINT UQ_Room_ScopeId UNIQUE (SchoolId, RoomId),
    CONSTRAINT FK_Room_Building FOREIGN KEY (SchoolId, BuildingId) REFERENCES academic.Building(SchoolId, BuildingId),
    CONSTRAINT CK_Room_Capacity CHECK (Capacity IS NULL OR Capacity > 0),
    CONSTRAINT CK_Room_Status CHECK (Status IN (''active'',''inactive'',''archived''))
  );

  CREATE TABLE academic.PeriodDefinition (
    PeriodId uniqueidentifier NOT NULL CONSTRAINT DF_Period_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    Code nvarchar(30) NOT NULL,
    Name nvarchar(80) NOT NULL,
    SequenceNo smallint NOT NULL,
    StartTime time(0) NOT NULL,
    EndTime time(0) NOT NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_Period_Status DEFAULT (''active''),
    CONSTRAINT PK_PeriodDefinition PRIMARY KEY CLUSTERED (PeriodId),
    CONSTRAINT UQ_Period_ScopeCode UNIQUE (SchoolId, Code),
    CONSTRAINT UQ_Period_ScopeId UNIQUE (SchoolId, PeriodId),
    CONSTRAINT FK_Period_School FOREIGN KEY (SchoolId) REFERENCES core.School(SchoolId),
    CONSTRAINT CK_Period_Time CHECK (StartTime < EndTime),
    CONSTRAINT CK_Period_Sequence CHECK (SequenceNo > 0)
  );

  CREATE TABLE people.StudentProfile (
    StudentId uniqueidentifier NOT NULL CONSTRAINT DF_Student_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    PersonId uniqueidentifier NOT NULL,
    StudentNumber nvarchar(50) NOT NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_Student_Status DEFAULT (''active''),
    CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_Student_Created DEFAULT SYSUTCDATETIME(),
    RowVersion rowversion NOT NULL,
    CONSTRAINT PK_StudentProfile PRIMARY KEY CLUSTERED (StudentId),
    CONSTRAINT UQ_Student_SchoolNumber UNIQUE (SchoolId, StudentNumber),
    CONSTRAINT UQ_Student_ScopeId UNIQUE (SchoolId, StudentId),
    CONSTRAINT UQ_Student_PersonSchool UNIQUE (SchoolId, PersonId),
    CONSTRAINT FK_Student_School FOREIGN KEY (SchoolId) REFERENCES core.School(SchoolId),
    CONSTRAINT FK_Student_Person FOREIGN KEY (PersonId) REFERENCES people.Person(PersonId),
    CONSTRAINT CK_Student_Status CHECK (Status IN (''active'',''inactive'',''withdrawn'',''graduated'',''archived''))
  );

  CREATE TABLE people.StudentExternalIdentifier (
    SchoolId uniqueidentifier NOT NULL,
    SourceSystem nvarchar(60) NOT NULL,
    ExternalId nvarchar(120) NOT NULL,
    StudentId uniqueidentifier NOT NULL,
    CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_StudentExternal_Created DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_StudentExternalIdentifier PRIMARY KEY (SchoolId, SourceSystem, ExternalId),
    CONSTRAINT UQ_StudentExternal_StudentSource UNIQUE (SchoolId, StudentId, SourceSystem),
    CONSTRAINT FK_StudentExternal_Student FOREIGN KEY (SchoolId, StudentId) REFERENCES people.StudentProfile(SchoolId, StudentId)
  );

  CREATE TABLE people.EmployeeProfile (
    EmployeeId uniqueidentifier NOT NULL CONSTRAINT DF_Employee_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    PersonId uniqueidentifier NOT NULL,
    EmployeeNumber nvarchar(50) NOT NULL,
    EmploymentStatus varchar(20) NOT NULL CONSTRAINT DF_Employee_Status DEFAULT (''active''),
    HireDate date NULL,
    TerminationDate date NULL,
    CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_Employee_Created DEFAULT SYSUTCDATETIME(),
    RowVersion rowversion NOT NULL,
    CONSTRAINT PK_EmployeeProfile PRIMARY KEY CLUSTERED (EmployeeId),
    CONSTRAINT UQ_Employee_SchoolNumber UNIQUE (SchoolId, EmployeeNumber),
    CONSTRAINT UQ_Employee_ScopeId UNIQUE (SchoolId, EmployeeId),
    CONSTRAINT UQ_Employee_PersonSchool UNIQUE (SchoolId, PersonId),
    CONSTRAINT FK_Employee_School FOREIGN KEY (SchoolId) REFERENCES core.School(SchoolId),
    CONSTRAINT FK_Employee_Person FOREIGN KEY (PersonId) REFERENCES people.Person(PersonId),
    CONSTRAINT CK_Employee_Dates CHECK (TerminationDate IS NULL OR HireDate IS NULL OR HireDate <= TerminationDate),
    CONSTRAINT CK_Employee_Status CHECK (EmploymentStatus IN (''active'',''on_leave'',''terminated'',''archived''))
  );

  CREATE TABLE people.GuardianProfile (
    GuardianId uniqueidentifier NOT NULL CONSTRAINT DF_Guardian_Id DEFAULT NEWSEQUENTIALID(),
    PersonId uniqueidentifier NOT NULL,
    CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_Guardian_Created DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_GuardianProfile PRIMARY KEY CLUSTERED (GuardianId),
    CONSTRAINT UQ_Guardian_Person UNIQUE (PersonId),
    CONSTRAINT FK_Guardian_Person FOREIGN KEY (PersonId) REFERENCES people.Person(PersonId)
  );

  CREATE TABLE people.StudentEnrollment (
    EnrollmentId uniqueidentifier NOT NULL CONSTRAINT DF_Enrollment_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    StudentId uniqueidentifier NOT NULL,
    SchoolYearId uniqueidentifier NOT NULL,
    ClassSectionId uniqueidentifier NOT NULL,
    StartDate date NOT NULL,
    EndDate date NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_Enrollment_Status DEFAULT (''active''),
    CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_Enrollment_Created DEFAULT SYSUTCDATETIME(),
    RowVersion rowversion NOT NULL,
    CONSTRAINT PK_StudentEnrollment PRIMARY KEY CLUSTERED (EnrollmentId),
    CONSTRAINT UQ_Enrollment_ScopeId UNIQUE (SchoolId, EnrollmentId),
    CONSTRAINT FK_Enrollment_Student FOREIGN KEY (SchoolId, StudentId) REFERENCES people.StudentProfile(SchoolId, StudentId),
    CONSTRAINT FK_Enrollment_Year FOREIGN KEY (SchoolId, SchoolYearId) REFERENCES core.SchoolYear(SchoolId, SchoolYearId),
    CONSTRAINT FK_Enrollment_Class FOREIGN KEY (SchoolId, SchoolYearId, ClassSectionId) REFERENCES academic.ClassSection(SchoolId, SchoolYearId, ClassSectionId),
    CONSTRAINT CK_Enrollment_Dates CHECK (EndDate IS NULL OR StartDate <= EndDate),
    CONSTRAINT CK_Enrollment_Status CHECK (Status IN (''active'',''transferred'',''withdrawn'',''completed'',''cancelled''))
  );

  CREATE TABLE people.StudentGuardian (
    StudentGuardianId uniqueidentifier NOT NULL CONSTRAINT DF_StudentGuardian_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    StudentId uniqueidentifier NOT NULL,
    GuardianId uniqueidentifier NOT NULL,
    RelationshipCode nvarchar(40) NOT NULL,
    IsPrimaryContact bit NOT NULL CONSTRAINT DF_StudentGuardian_Primary DEFAULT (0),
    CanViewAttendance bit NOT NULL CONSTRAINT DF_StudentGuardian_Attendance DEFAULT (1),
    CanViewGrades bit NOT NULL CONSTRAINT DF_StudentGuardian_Grades DEFAULT (1),
    CanViewFinance bit NOT NULL CONSTRAINT DF_StudentGuardian_Finance DEFAULT (0),
    ValidFrom date NOT NULL,
    ValidTo date NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_StudentGuardian_Status DEFAULT (''active''),
    CONSTRAINT PK_StudentGuardian PRIMARY KEY CLUSTERED (StudentGuardianId),
    CONSTRAINT UQ_StudentGuardian_ScopeId UNIQUE (SchoolId, StudentGuardianId),
    CONSTRAINT FK_StudentGuardian_Student FOREIGN KEY (SchoolId, StudentId) REFERENCES people.StudentProfile(SchoolId, StudentId),
    CONSTRAINT FK_StudentGuardian_Guardian FOREIGN KEY (GuardianId) REFERENCES people.GuardianProfile(GuardianId),
    CONSTRAINT CK_StudentGuardian_Dates CHECK (ValidTo IS NULL OR ValidFrom <= ValidTo),
    CONSTRAINT CK_StudentGuardian_Status CHECK (Status IN (''active'',''revoked'',''expired''))
  );

  CREATE TABLE academic.TeachingAssignment (
    TeachingAssignmentId uniqueidentifier NOT NULL CONSTRAINT DF_TeachingAssignment_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    SchoolYearId uniqueidentifier NOT NULL,
    TermId uniqueidentifier NOT NULL,
    EmployeeId uniqueidentifier NOT NULL,
    SubjectId uniqueidentifier NOT NULL,
    ClassSectionId uniqueidentifier NOT NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_TeachingAssignment_Status DEFAULT (''active''),
    CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_TeachingAssignment_Created DEFAULT SYSUTCDATETIME(),
    RowVersion rowversion NOT NULL,
    CONSTRAINT PK_TeachingAssignment PRIMARY KEY CLUSTERED (TeachingAssignmentId),
    CONSTRAINT UQ_TeachingAssignment_ScopeId UNIQUE (SchoolId, TeachingAssignmentId),
    CONSTRAINT UQ_TeachingAssignment_Logical UNIQUE (SchoolId, SchoolYearId, TermId, EmployeeId, SubjectId, ClassSectionId),
    CONSTRAINT FK_TeachingAssignment_Year FOREIGN KEY (SchoolId, SchoolYearId) REFERENCES core.SchoolYear(SchoolId, SchoolYearId),
    CONSTRAINT FK_TeachingAssignment_Term FOREIGN KEY (SchoolId, SchoolYearId, TermId) REFERENCES core.AcademicTerm(SchoolId, SchoolYearId, TermId),
    CONSTRAINT FK_TeachingAssignment_Employee FOREIGN KEY (SchoolId, EmployeeId) REFERENCES people.EmployeeProfile(SchoolId, EmployeeId),
    CONSTRAINT FK_TeachingAssignment_Subject FOREIGN KEY (SchoolId, SubjectId) REFERENCES academic.Subject(SchoolId, SubjectId),
    CONSTRAINT FK_TeachingAssignment_Class FOREIGN KEY (SchoolId, SchoolYearId, ClassSectionId) REFERENCES academic.ClassSection(SchoolId, SchoolYearId, ClassSectionId),
    CONSTRAINT CK_TeachingAssignment_Status CHECK (Status IN (''active'',''inactive'',''ended''))
  );

  CREATE TABLE academic.TimetableLesson (
    TimetableLessonId uniqueidentifier NOT NULL CONSTRAINT DF_TimetableLesson_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    SchoolYearId uniqueidentifier NOT NULL,
    TermId uniqueidentifier NOT NULL,
    TeachingAssignmentId uniqueidentifier NOT NULL,
    DayOfWeek tinyint NOT NULL,
    PeriodId uniqueidentifier NOT NULL,
    RoomId uniqueidentifier NULL,
    EffectiveFrom date NOT NULL,
    EffectiveTo date NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_TimetableLesson_Status DEFAULT (''active''),
    CONSTRAINT PK_TimetableLesson PRIMARY KEY CLUSTERED (TimetableLessonId),
    CONSTRAINT UQ_TimetableLesson_ScopeId UNIQUE (SchoolId, TimetableLessonId),
    CONSTRAINT FK_TimetableLesson_Assignment FOREIGN KEY (SchoolId, TeachingAssignmentId) REFERENCES academic.TeachingAssignment(SchoolId, TeachingAssignmentId),
    CONSTRAINT FK_TimetableLesson_Period FOREIGN KEY (SchoolId, PeriodId) REFERENCES academic.PeriodDefinition(SchoolId, PeriodId),
    CONSTRAINT FK_TimetableLesson_Room FOREIGN KEY (SchoolId, RoomId) REFERENCES academic.Room(SchoolId, RoomId),
    CONSTRAINT CK_TimetableLesson_Day CHECK (DayOfWeek BETWEEN 1 AND 7),
    CONSTRAINT CK_TimetableLesson_Dates CHECK (EffectiveTo IS NULL OR EffectiveFrom <= EffectiveTo),
    CONSTRAINT CK_TimetableLesson_Status CHECK (Status IN (''active'',''cancelled'',''archived''))
  );

  CREATE INDEX IX_ClassSection_YearGrade ON academic.ClassSection(SchoolId, SchoolYearId, GradeLevelId, Status);
  CREATE INDEX IX_Enrollment_StudentYear ON people.StudentEnrollment(SchoolId, StudentId, SchoolYearId, Status);
  CREATE INDEX IX_Enrollment_ClassStatus ON people.StudentEnrollment(SchoolId, ClassSectionId, Status) INCLUDE (StudentId, StartDate, EndDate);
  CREATE INDEX IX_TeachingAssignment_EmployeeTerm ON academic.TeachingAssignment(SchoolId, EmployeeId, SchoolYearId, TermId, Status);
  CREATE INDEX IX_TimetableLesson_AssignmentDay ON academic.TimetableLesson(SchoolId, TeachingAssignmentId, DayOfWeek, PeriodId, Status);
  CREATE INDEX IX_StudentGuardian_Guardian ON people.StudentGuardian(GuardianId, SchoolId, Status) INCLUDE (StudentId, CanViewGrades, CanViewAttendance, CanViewFinance);

  
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
  THROW;
END CATCH;
';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(2,N''002_academic_structure.sql'',0x2ed6ddca804b2ec595caf75d6d9481327d6733e994f4f0d641d8b48843291eec,''executed'');';
 -- BEGIN 003_learning_assessment.sql
 EXEC sys.sp_executesql N'SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;';
 EXEC sys.sp_executesql N'
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY
  
  IF SCHEMA_ID(N''attendance'') IS NULL EXEC(N''CREATE SCHEMA attendance AUTHORIZATION dbo'');
  IF SCHEMA_ID(N''learning'') IS NULL EXEC(N''CREATE SCHEMA learning AUTHORIZATION dbo'');
  IF SCHEMA_ID(N''assessment'') IS NULL EXEC(N''CREATE SCHEMA assessment AUTHORIZATION dbo'');

  CREATE TABLE core.FileObject (
    FileObjectId uniqueidentifier NOT NULL CONSTRAINT DF_FileObject_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    StorageKey nvarchar(500) NOT NULL,
    OriginalName nvarchar(255) NOT NULL,
    ContentType varchar(150) NOT NULL,
    SizeBytes bigint NOT NULL,
    Sha256 binary(32) NOT NULL,
    Classification varchar(30) NOT NULL,
    UploadedByUserId uniqueidentifier NOT NULL,
    CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_FileObject_Created DEFAULT SYSUTCDATETIME(),
    Status varchar(20) NOT NULL CONSTRAINT DF_FileObject_Status DEFAULT (''active''),
    CONSTRAINT PK_FileObject PRIMARY KEY CLUSTERED (FileObjectId),
    CONSTRAINT UQ_FileObject_SchoolId UNIQUE (SchoolId, FileObjectId),
    CONSTRAINT UQ_FileObject_StorageKey UNIQUE (StorageKey),
    CONSTRAINT FK_FileObject_School FOREIGN KEY (SchoolId) REFERENCES core.School(SchoolId),
    CONSTRAINT FK_FileObject_Uploader FOREIGN KEY (UploadedByUserId) REFERENCES security.UserAccount(UserId),
    CONSTRAINT CK_FileObject_Size CHECK (SizeBytes > 0),
    CONSTRAINT CK_FileObject_Classification CHECK (Classification IN (''public'',''internal'',''personal'',''sensitive'',''clinical'')),
    CONSTRAINT CK_FileObject_Status CHECK (Status IN (''active'',''quarantined'',''deleted''))
  );

  CREATE TABLE attendance.AttendanceSession (
    AttendanceSessionId uniqueidentifier NOT NULL CONSTRAINT DF_AttendanceSession_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    SessionDate date NOT NULL,
    SessionType varchar(20) NOT NULL,
    ClassSectionId uniqueidentifier NULL,
    PeriodId uniqueidentifier NULL,
    TakenByUserId uniqueidentifier NOT NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_AttendanceSession_Status DEFAULT (''draft''),
    SubmittedAtUtc datetime2(3) NULL,
    CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_AttendanceSession_Created DEFAULT SYSUTCDATETIME(),
    RowVersion rowversion NOT NULL,
    CONSTRAINT PK_AttendanceSession PRIMARY KEY CLUSTERED (AttendanceSessionId),
    CONSTRAINT UQ_AttendanceSession_ScopeId UNIQUE (SchoolId, AttendanceSessionId),
    CONSTRAINT FK_AttendanceSession_School FOREIGN KEY (SchoolId) REFERENCES core.School(SchoolId),
    CONSTRAINT FK_AttendanceSession_Class FOREIGN KEY (SchoolId, ClassSectionId) REFERENCES academic.ClassSection(SchoolId, ClassSectionId),
    CONSTRAINT FK_AttendanceSession_Period FOREIGN KEY (SchoolId, PeriodId) REFERENCES academic.PeriodDefinition(SchoolId, PeriodId),
    CONSTRAINT FK_AttendanceSession_Taker FOREIGN KEY (TakenByUserId) REFERENCES security.UserAccount(UserId),
    CONSTRAINT CK_AttendanceSession_Type CHECK (SessionType IN (''student_class'',''student_day'',''employee_shift'')),
    CONSTRAINT CK_AttendanceSession_Status CHECK (Status IN (''draft'',''submitted'',''locked'',''cancelled'')),
    CONSTRAINT CK_AttendanceSession_Scope CHECK ((SessionType=''student_class'' AND ClassSectionId IS NOT NULL) OR (SessionType<>''student_class''))
  );

  CREATE TABLE attendance.StudentAttendance (
    AttendanceSessionId uniqueidentifier NOT NULL,
    SchoolId uniqueidentifier NOT NULL,
    EnrollmentId uniqueidentifier NOT NULL,
    StatusCode varchar(20) NOT NULL,
    Reason nvarchar(500) NULL,
    Source varchar(20) NOT NULL CONSTRAINT DF_StudentAttendance_Source DEFAULT (''manual''),
    RecordedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_StudentAttendance_Recorded DEFAULT SYSUTCDATETIME(),
    RecordedByUserId uniqueidentifier NOT NULL,
    CONSTRAINT PK_StudentAttendance PRIMARY KEY (AttendanceSessionId, EnrollmentId),
    CONSTRAINT FK_StudentAttendance_Session FOREIGN KEY (SchoolId, AttendanceSessionId) REFERENCES attendance.AttendanceSession(SchoolId, AttendanceSessionId),
    CONSTRAINT FK_StudentAttendance_Enrollment FOREIGN KEY (SchoolId, EnrollmentId) REFERENCES people.StudentEnrollment(SchoolId, EnrollmentId),
    CONSTRAINT FK_StudentAttendance_Recorder FOREIGN KEY (RecordedByUserId) REFERENCES security.UserAccount(UserId),
    CONSTRAINT CK_StudentAttendance_Status CHECK (StatusCode IN (''present'',''absent'',''late'',''excused'',''left_early'')),
    CONSTRAINT CK_StudentAttendance_Source CHECK (Source IN (''manual'',''import'',''device'',''api''))
  );

  CREATE TABLE attendance.EmployeeAttendance (
    EmployeeAttendanceId uniqueidentifier NOT NULL CONSTRAINT DF_EmployeeAttendance_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    EmployeeId uniqueidentifier NOT NULL,
    WorkDate date NOT NULL,
    ShiftCode nvarchar(40) NOT NULL CONSTRAINT DF_EmployeeAttendance_Shift DEFAULT (N''default''),
    StatusCode varchar(20) NOT NULL,
    ClockInAtUtc datetime2(3) NULL,
    ClockOutAtUtc datetime2(3) NULL,
    Source varchar(20) NOT NULL CONSTRAINT DF_EmployeeAttendance_Source DEFAULT (''manual''),
    RecordedByUserId uniqueidentifier NOT NULL,
    RowVersion rowversion NOT NULL,
    CONSTRAINT PK_EmployeeAttendance PRIMARY KEY CLUSTERED (EmployeeAttendanceId),
    CONSTRAINT UQ_EmployeeAttendance_Day UNIQUE (SchoolId, EmployeeId, WorkDate, ShiftCode),
    CONSTRAINT FK_EmployeeAttendance_Employee FOREIGN KEY (SchoolId, EmployeeId) REFERENCES people.EmployeeProfile(SchoolId, EmployeeId),
    CONSTRAINT FK_EmployeeAttendance_Recorder FOREIGN KEY (RecordedByUserId) REFERENCES security.UserAccount(UserId),
    CONSTRAINT CK_EmployeeAttendance_Status CHECK (StatusCode IN (''present'',''absent'',''late'',''excused'',''on_leave'')),
    CONSTRAINT CK_EmployeeAttendance_Clock CHECK (ClockOutAtUtc IS NULL OR ClockInAtUtc IS NULL OR ClockInAtUtc <= ClockOutAtUtc)
  );

  CREATE TABLE attendance.LeaveRequest (
    LeaveRequestId uniqueidentifier NOT NULL CONSTRAINT DF_LeaveRequest_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    EmployeeId uniqueidentifier NOT NULL,
    LeaveTypeCode varchar(40) NOT NULL,
    StartDate date NOT NULL,
    EndDate date NOT NULL,
    Reason nvarchar(2000) NOT NULL,
    AttachmentFileObjectId uniqueidentifier NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_LeaveRequest_Status DEFAULT (''submitted''),
    SubmittedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_LeaveRequest_Submitted DEFAULT SYSUTCDATETIME(),
    RowVersion rowversion NOT NULL,
    CONSTRAINT PK_LeaveRequest PRIMARY KEY CLUSTERED (LeaveRequestId),
    CONSTRAINT UQ_LeaveRequest_ScopeId UNIQUE (SchoolId, LeaveRequestId),
    CONSTRAINT FK_LeaveRequest_Employee FOREIGN KEY (SchoolId, EmployeeId) REFERENCES people.EmployeeProfile(SchoolId, EmployeeId),
    CONSTRAINT FK_LeaveRequest_File FOREIGN KEY (SchoolId, AttachmentFileObjectId) REFERENCES core.FileObject(SchoolId, FileObjectId),
    CONSTRAINT CK_LeaveRequest_Dates CHECK (StartDate <= EndDate),
    CONSTRAINT CK_LeaveRequest_Status CHECK (Status IN (''submitted'',''approved'',''rejected'',''cancelled'',''withdrawn''))
  );

  CREATE TABLE attendance.LeaveDecision (
    LeaveDecisionId uniqueidentifier NOT NULL CONSTRAINT DF_LeaveDecision_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    LeaveRequestId uniqueidentifier NOT NULL,
    ActorUserId uniqueidentifier NOT NULL,
    Decision varchar(20) NOT NULL,
    Note nvarchar(1000) NULL,
    OccurredAtUtc datetime2(3) NOT NULL CONSTRAINT DF_LeaveDecision_At DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_LeaveDecision PRIMARY KEY CLUSTERED (LeaveDecisionId),
    CONSTRAINT FK_LeaveDecision_Request FOREIGN KEY (SchoolId, LeaveRequestId) REFERENCES attendance.LeaveRequest(SchoolId, LeaveRequestId),
    CONSTRAINT FK_LeaveDecision_Actor FOREIGN KEY (ActorUserId) REFERENCES security.UserAccount(UserId),
    CONSTRAINT CK_LeaveDecision_Decision CHECK (Decision IN (''approved'',''rejected'',''cancelled''))
  );

  CREATE TABLE attendance.CoverAssignment (
    CoverAssignmentId uniqueidentifier NOT NULL CONSTRAINT DF_Cover_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    LeaveRequestId uniqueidentifier NOT NULL,
    TimetableLessonId uniqueidentifier NOT NULL,
    SubstituteEmployeeId uniqueidentifier NOT NULL,
    CoverDate date NOT NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_Cover_Status DEFAULT (''active''),
    Reason nvarchar(1000) NULL,
    AssignedByUserId uniqueidentifier NOT NULL,
    CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_Cover_Created DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_CoverAssignment PRIMARY KEY CLUSTERED (CoverAssignmentId),
    CONSTRAINT UQ_Cover_ScopeId UNIQUE (SchoolId, CoverAssignmentId),
    CONSTRAINT FK_Cover_Leave FOREIGN KEY (SchoolId, LeaveRequestId) REFERENCES attendance.LeaveRequest(SchoolId, LeaveRequestId),
    CONSTRAINT FK_Cover_Lesson FOREIGN KEY (SchoolId, TimetableLessonId) REFERENCES academic.TimetableLesson(SchoolId, TimetableLessonId),
    CONSTRAINT FK_Cover_Substitute FOREIGN KEY (SchoolId, SubstituteEmployeeId) REFERENCES people.EmployeeProfile(SchoolId, EmployeeId),
    CONSTRAINT FK_Cover_Assigner FOREIGN KEY (AssignedByUserId) REFERENCES security.UserAccount(UserId),
    CONSTRAINT CK_Cover_Status CHECK (Status IN (''active'',''cancelled'',''completed''))
  );
  CREATE UNIQUE INDEX UX_Cover_ActiveLessonDate ON attendance.CoverAssignment(SchoolId, TimetableLessonId, CoverDate) WHERE Status=''active'';

  CREATE TABLE learning.[Plan] (
    PlanId uniqueidentifier NOT NULL CONSTRAINT DF_Plan_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    TeachingAssignmentId uniqueidentifier NOT NULL,
    PlanType varchar(20) NOT NULL,
    Title nvarchar(200) NOT NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_Plan_Status DEFAULT (''draft''),
    CurrentVersionNo int NOT NULL CONSTRAINT DF_Plan_Version DEFAULT (1),
    CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_Plan_Created DEFAULT SYSUTCDATETIME(),
    RowVersion rowversion NOT NULL,
    CONSTRAINT PK_Plan PRIMARY KEY CLUSTERED (PlanId),
    CONSTRAINT UQ_Plan_ScopeId UNIQUE (SchoolId, PlanId),
    CONSTRAINT FK_Plan_Assignment FOREIGN KEY (SchoolId, TeachingAssignmentId) REFERENCES academic.TeachingAssignment(SchoolId, TeachingAssignmentId),
    CONSTRAINT CK_Plan_Type CHECK (PlanType IN (''daily'',''term'')),
    CONSTRAINT CK_Plan_Status CHECK (Status IN (''draft'',''submitted'',''returned'',''approved'',''archived'')),
    CONSTRAINT CK_Plan_Version CHECK (CurrentVersionNo > 0)
  );

  CREATE TABLE learning.PlanVersion (
    PlanVersionId uniqueidentifier NOT NULL CONSTRAINT DF_PlanVersion_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    PlanId uniqueidentifier NOT NULL,
    VersionNo int NOT NULL,
    PayloadJson nvarchar(max) NOT NULL,
    ContentHash binary(32) NOT NULL,
    CreatedByUserId uniqueidentifier NOT NULL,
    CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_PlanVersion_Created DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_PlanVersion PRIMARY KEY CLUSTERED (PlanVersionId),
    CONSTRAINT UQ_PlanVersion_Number UNIQUE (SchoolId, PlanId, VersionNo),
    CONSTRAINT UQ_PlanVersion_ScopeId UNIQUE (SchoolId, PlanVersionId),
    CONSTRAINT FK_PlanVersion_Plan FOREIGN KEY (SchoolId, PlanId) REFERENCES learning.[Plan](SchoolId, PlanId),
    CONSTRAINT FK_PlanVersion_Author FOREIGN KEY (CreatedByUserId) REFERENCES security.UserAccount(UserId),
    CONSTRAINT CK_PlanVersion_Json CHECK (ISJSON(PayloadJson)=1),
    CONSTRAINT CK_PlanVersion_Number CHECK (VersionNo > 0)
  );

  CREATE TABLE learning.PlanReview (
    PlanReviewId uniqueidentifier NOT NULL CONSTRAINT DF_PlanReview_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    PlanVersionId uniqueidentifier NOT NULL,
    ReviewerUserId uniqueidentifier NOT NULL,
    Decision varchar(20) NOT NULL,
    Comments nvarchar(3000) NULL,
    ReviewedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_PlanReview_At DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_PlanReview PRIMARY KEY CLUSTERED (PlanReviewId),
    CONSTRAINT FK_PlanReview_Version FOREIGN KEY (SchoolId, PlanVersionId) REFERENCES learning.PlanVersion(SchoolId, PlanVersionId),
    CONSTRAINT FK_PlanReview_Reviewer FOREIGN KEY (ReviewerUserId) REFERENCES security.UserAccount(UserId),
    CONSTRAINT CK_PlanReview_Decision CHECK (Decision IN (''approved'',''returned''))
  );

  CREATE TABLE learning.Assignment (
    AssignmentId uniqueidentifier NOT NULL CONSTRAINT DF_Assignment_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    TeachingAssignmentId uniqueidentifier NOT NULL,
    Title nvarchar(200) NOT NULL,
    Instructions nvarchar(max) NULL,
    DueAtLocal datetime2(0) NOT NULL,
    MaximumScore decimal(9,4) NOT NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_Assignment_Status DEFAULT (''published''),
    CreatedByUserId uniqueidentifier NOT NULL,
    CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_Assignment_Created DEFAULT SYSUTCDATETIME(),
    RowVersion rowversion NOT NULL,
    CONSTRAINT PK_Assignment PRIMARY KEY CLUSTERED (AssignmentId),
    CONSTRAINT UQ_Assignment_ScopeId UNIQUE (SchoolId, AssignmentId),
    CONSTRAINT FK_Assignment_Teaching FOREIGN KEY (SchoolId, TeachingAssignmentId) REFERENCES academic.TeachingAssignment(SchoolId, TeachingAssignmentId),
    CONSTRAINT FK_Assignment_Creator FOREIGN KEY (CreatedByUserId) REFERENCES security.UserAccount(UserId),
    CONSTRAINT CK_Assignment_MaxScore CHECK (MaximumScore > 0),
    CONSTRAINT CK_Assignment_Status CHECK (Status IN (''draft'',''published'',''closed'',''archived''))
  );

  CREATE TABLE learning.AssignmentFile (
    AssignmentId uniqueidentifier NOT NULL,
    SchoolId uniqueidentifier NOT NULL,
    FileObjectId uniqueidentifier NOT NULL,
    SortOrder smallint NOT NULL CONSTRAINT DF_AssignmentFile_Order DEFAULT (1),
    CONSTRAINT PK_AssignmentFile PRIMARY KEY (AssignmentId, FileObjectId),
    CONSTRAINT FK_AssignmentFile_Assignment FOREIGN KEY (SchoolId, AssignmentId) REFERENCES learning.Assignment(SchoolId, AssignmentId),
    CONSTRAINT FK_AssignmentFile_File FOREIGN KEY (SchoolId, FileObjectId) REFERENCES core.FileObject(SchoolId, FileObjectId),
    CONSTRAINT CK_AssignmentFile_Order CHECK (SortOrder > 0)
  );

  CREATE TABLE learning.Submission (
    SubmissionId uniqueidentifier NOT NULL CONSTRAINT DF_Submission_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    AssignmentId uniqueidentifier NOT NULL,
    EnrollmentId uniqueidentifier NOT NULL,
    CurrentRevisionNo int NOT NULL CONSTRAINT DF_Submission_Revision DEFAULT (1),
    Status varchar(20) NOT NULL CONSTRAINT DF_Submission_Status DEFAULT (''draft''),
    CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_Submission_Created DEFAULT SYSUTCDATETIME(),
    RowVersion rowversion NOT NULL,
    CONSTRAINT PK_Submission PRIMARY KEY CLUSTERED (SubmissionId),
    CONSTRAINT UQ_Submission_AssignmentEnrollment UNIQUE (SchoolId, AssignmentId, EnrollmentId),
    CONSTRAINT UQ_Submission_ScopeId UNIQUE (SchoolId, SubmissionId),
    CONSTRAINT FK_Submission_Assignment FOREIGN KEY (SchoolId, AssignmentId) REFERENCES learning.Assignment(SchoolId, AssignmentId),
    CONSTRAINT FK_Submission_Enrollment FOREIGN KEY (SchoolId, EnrollmentId) REFERENCES people.StudentEnrollment(SchoolId, EnrollmentId),
    CONSTRAINT CK_Submission_Revision CHECK (CurrentRevisionNo > 0),
    CONSTRAINT CK_Submission_Status CHECK (Status IN (''draft'',''submitted'',''returned'',''graded'',''late'',''withdrawn''))
  );

  CREATE TABLE learning.SubmissionRevision (
    SubmissionRevisionId uniqueidentifier NOT NULL CONSTRAINT DF_SubmissionRevision_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    SubmissionId uniqueidentifier NOT NULL,
    RevisionNo int NOT NULL,
    TextAnswer nvarchar(max) NULL,
    AttachmentFileObjectId uniqueidentifier NULL,
    SubmittedAtUtc datetime2(3) NULL,
    Score decimal(9,4) NULL,
    Feedback nvarchar(3000) NULL,
    ReviewedByUserId uniqueidentifier NULL,
    ReviewedAtUtc datetime2(3) NULL,
    CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_SubmissionRevision_Created DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_SubmissionRevision PRIMARY KEY CLUSTERED (SubmissionRevisionId),
    CONSTRAINT UQ_SubmissionRevision_Number UNIQUE (SchoolId, SubmissionId, RevisionNo),
    CONSTRAINT FK_SubmissionRevision_Submission FOREIGN KEY (SchoolId, SubmissionId) REFERENCES learning.Submission(SchoolId, SubmissionId),
    CONSTRAINT FK_SubmissionRevision_File FOREIGN KEY (SchoolId, AttachmentFileObjectId) REFERENCES core.FileObject(SchoolId, FileObjectId),
    CONSTRAINT FK_SubmissionRevision_Reviewer FOREIGN KEY (ReviewedByUserId) REFERENCES security.UserAccount(UserId),
    CONSTRAINT CK_SubmissionRevision_Number CHECK (RevisionNo > 0),
    CONSTRAINT CK_SubmissionRevision_Score CHECK (Score IS NULL OR Score >= 0)
  );

  CREATE TABLE assessment.GradingPolicy (
    GradingPolicyId uniqueidentifier NOT NULL CONSTRAINT DF_GradingPolicy_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    SchoolYearId uniqueidentifier NOT NULL,
    TermId uniqueidentifier NOT NULL,
    StageId uniqueidentifier NOT NULL,
    GradeLevelId uniqueidentifier NULL,
    SubjectId uniqueidentifier NULL,
    Code nvarchar(50) NOT NULL,
    VersionNo int NOT NULL,
    AssessmentMode varchar(20) NOT NULL,
    RoundingRule varchar(20) NOT NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_GradingPolicy_Status DEFAULT (''draft''),
    EffectiveFrom date NOT NULL,
    EffectiveTo date NULL,
    CreatedByUserId uniqueidentifier NOT NULL,
    CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_GradingPolicy_Created DEFAULT SYSUTCDATETIME(),
    RowVersion rowversion NOT NULL,
    CONSTRAINT PK_GradingPolicy PRIMARY KEY CLUSTERED (GradingPolicyId),
    CONSTRAINT UQ_GradingPolicy_ScopeId UNIQUE (SchoolId, GradingPolicyId),
    CONSTRAINT UQ_GradingPolicy_Version UNIQUE (SchoolId, Code, VersionNo),
    CONSTRAINT FK_GradingPolicy_Year FOREIGN KEY (SchoolId, SchoolYearId) REFERENCES core.SchoolYear(SchoolId, SchoolYearId),
    CONSTRAINT FK_GradingPolicy_Term FOREIGN KEY (SchoolId, SchoolYearId, TermId) REFERENCES core.AcademicTerm(SchoolId, SchoolYearId, TermId),
    CONSTRAINT FK_GradingPolicy_Stage FOREIGN KEY (SchoolId, StageId) REFERENCES academic.Stage(SchoolId, StageId),
    CONSTRAINT FK_GradingPolicy_Grade FOREIGN KEY (SchoolId, GradeLevelId) REFERENCES academic.GradeLevel(SchoolId, GradeLevelId),
    CONSTRAINT FK_GradingPolicy_Subject FOREIGN KEY (SchoolId, SubjectId) REFERENCES academic.Subject(SchoolId, SubjectId),
    CONSTRAINT FK_GradingPolicy_Author FOREIGN KEY (CreatedByUserId) REFERENCES security.UserAccount(UserId),
    CONSTRAINT CK_GradingPolicy_Version CHECK (VersionNo > 0),
    CONSTRAINT CK_GradingPolicy_Mode CHECK (AssessmentMode IN (''weighted'',''descriptive'',''hybrid'')),
    CONSTRAINT CK_GradingPolicy_Rounding CHECK (RoundingRule IN (''none'',''nearest'',''floor'',''ceiling'')),
    CONSTRAINT CK_GradingPolicy_Dates CHECK (EffectiveTo IS NULL OR EffectiveFrom <= EffectiveTo),
    CONSTRAINT CK_GradingPolicy_Status CHECK (Status IN (''draft'',''approved'',''retired''))
  );

  CREATE TABLE assessment.GradingComponent (
    GradingComponentId uniqueidentifier NOT NULL CONSTRAINT DF_GradingComponent_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    GradingPolicyId uniqueidentifier NOT NULL,
    Code nvarchar(50) NOT NULL,
    Name nvarchar(160) NOT NULL,
    MaximumScore decimal(9,4) NULL,
    WeightPercent decimal(7,4) NULL,
    SortOrder smallint NOT NULL,
    IsRequired bit NOT NULL CONSTRAINT DF_GradingComponent_Required DEFAULT (1),
    CONSTRAINT PK_GradingComponent PRIMARY KEY CLUSTERED (GradingComponentId),
    CONSTRAINT UQ_GradingComponent_PolicyCode UNIQUE (SchoolId, GradingPolicyId, Code),
    CONSTRAINT UQ_GradingComponent_ScopeId UNIQUE (SchoolId, GradingComponentId),
    CONSTRAINT FK_GradingComponent_Policy FOREIGN KEY (SchoolId, GradingPolicyId) REFERENCES assessment.GradingPolicy(SchoolId, GradingPolicyId),
    CONSTRAINT CK_GradingComponent_Max CHECK (MaximumScore IS NULL OR MaximumScore > 0),
    CONSTRAINT CK_GradingComponent_Weight CHECK (WeightPercent IS NULL OR (WeightPercent >= 0 AND WeightPercent <= 100)),
    CONSTRAINT CK_GradingComponent_Sort CHECK (SortOrder >= 0)
  );

  CREATE TABLE assessment.Gradebook (
    GradebookId uniqueidentifier NOT NULL CONSTRAINT DF_Gradebook_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    TeachingAssignmentId uniqueidentifier NOT NULL,
    GradingPolicyId uniqueidentifier NOT NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_Gradebook_Status DEFAULT (''draft''),
    Revision int NOT NULL CONSTRAINT DF_Gradebook_Revision DEFAULT (1),
    LockedAtUtc datetime2(3) NULL,
    CreatedByUserId uniqueidentifier NOT NULL,
    CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_Gradebook_Created DEFAULT SYSUTCDATETIME(),
    RowVersion rowversion NOT NULL,
    CONSTRAINT PK_Gradebook PRIMARY KEY CLUSTERED (GradebookId),
    CONSTRAINT UQ_Gradebook_ScopeId UNIQUE (SchoolId, GradebookId),
    CONSTRAINT UQ_Gradebook_AssignmentPolicy UNIQUE (SchoolId, TeachingAssignmentId, GradingPolicyId),
    CONSTRAINT FK_Gradebook_Teaching FOREIGN KEY (SchoolId, TeachingAssignmentId) REFERENCES academic.TeachingAssignment(SchoolId, TeachingAssignmentId),
    CONSTRAINT FK_Gradebook_Policy FOREIGN KEY (SchoolId, GradingPolicyId) REFERENCES assessment.GradingPolicy(SchoolId, GradingPolicyId),
    CONSTRAINT FK_Gradebook_Creator FOREIGN KEY (CreatedByUserId) REFERENCES security.UserAccount(UserId),
    CONSTRAINT CK_Gradebook_Status CHECK (Status IN (''draft'',''submitted'',''returned'',''reviewed'',''approved'',''published'',''locked'',''reopen_requested'',''archived'')),
    CONSTRAINT CK_Gradebook_Revision CHECK (Revision > 0)
  );

  CREATE TABLE assessment.GradeItem (
    GradeItemId uniqueidentifier NOT NULL CONSTRAINT DF_GradeItem_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    GradebookId uniqueidentifier NOT NULL,
    GradingComponentId uniqueidentifier NOT NULL,
    EnrollmentId uniqueidentifier NOT NULL,
    Score decimal(9,4) NULL,
    DescriptiveLevel nvarchar(100) NULL,
    Feedback nvarchar(2000) NULL,
    UpdatedByUserId uniqueidentifier NOT NULL,
    UpdatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_GradeItem_Updated DEFAULT SYSUTCDATETIME(),
    RowVersion rowversion NOT NULL,
    CONSTRAINT PK_GradeItem PRIMARY KEY CLUSTERED (GradeItemId),
    CONSTRAINT UQ_GradeItem_StudentComponent UNIQUE (SchoolId, GradebookId, GradingComponentId, EnrollmentId),
    CONSTRAINT FK_GradeItem_Gradebook FOREIGN KEY (SchoolId, GradebookId) REFERENCES assessment.Gradebook(SchoolId, GradebookId),
    CONSTRAINT FK_GradeItem_Component FOREIGN KEY (SchoolId, GradingComponentId) REFERENCES assessment.GradingComponent(SchoolId, GradingComponentId),
    CONSTRAINT FK_GradeItem_Enrollment FOREIGN KEY (SchoolId, EnrollmentId) REFERENCES people.StudentEnrollment(SchoolId, EnrollmentId),
    CONSTRAINT FK_GradeItem_Updater FOREIGN KEY (UpdatedByUserId) REFERENCES security.UserAccount(UserId),
    CONSTRAINT CK_GradeItem_NonNegative CHECK (Score IS NULL OR Score >= 0),
    CONSTRAINT CK_GradeItem_Representation CHECK (Score IS NOT NULL OR DescriptiveLevel IS NOT NULL)
  );

  CREATE TABLE assessment.GradebookWorkflowEvent (
    WorkflowEventId bigint IDENTITY(1,1) NOT NULL,
    SchoolId uniqueidentifier NOT NULL,
    GradebookId uniqueidentifier NOT NULL,
    ActorUserId uniqueidentifier NOT NULL,
    FromStatus varchar(30) NULL,
    ToStatus varchar(30) NOT NULL,
    Note nvarchar(2000) NULL,
    Revision int NOT NULL,
    OccurredAtUtc datetime2(3) NOT NULL CONSTRAINT DF_GradebookEvent_At DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_GradebookWorkflowEvent PRIMARY KEY CLUSTERED (WorkflowEventId),
    CONSTRAINT FK_GradebookEvent_Gradebook FOREIGN KEY (SchoolId, GradebookId) REFERENCES assessment.Gradebook(SchoolId, GradebookId),
    CONSTRAINT FK_GradebookEvent_Actor FOREIGN KEY (ActorUserId) REFERENCES security.UserAccount(UserId),
    CONSTRAINT CK_GradebookEvent_Revision CHECK (Revision > 0)
  );

  CREATE TABLE assessment.GradePublication (
    GradePublicationId uniqueidentifier NOT NULL CONSTRAINT DF_GradePublication_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    GradebookId uniqueidentifier NOT NULL,
    VersionNo int NOT NULL,
    SnapshotHash binary(32) NOT NULL,
    PublishedByUserId uniqueidentifier NOT NULL,
    PublishedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_GradePublication_At DEFAULT SYSUTCDATETIME(),
    RevokedAtUtc datetime2(3) NULL,
    RevocationReason nvarchar(1000) NULL,
    CONSTRAINT PK_GradePublication PRIMARY KEY CLUSTERED (GradePublicationId),
    CONSTRAINT UQ_GradePublication_Version UNIQUE (SchoolId, GradebookId, VersionNo),
    CONSTRAINT UQ_GradePublication_ScopeId UNIQUE (SchoolId, GradePublicationId),
    CONSTRAINT FK_GradePublication_Gradebook FOREIGN KEY (SchoolId, GradebookId) REFERENCES assessment.Gradebook(SchoolId, GradebookId),
    CONSTRAINT FK_GradePublication_Publisher FOREIGN KEY (PublishedByUserId) REFERENCES security.UserAccount(UserId),
    CONSTRAINT CK_GradePublication_Version CHECK (VersionNo > 0),
    CONSTRAINT CK_GradePublication_Revocation CHECK ((RevokedAtUtc IS NULL AND RevocationReason IS NULL) OR (RevokedAtUtc IS NOT NULL AND RevocationReason IS NOT NULL))
  );

  CREATE TABLE assessment.PublishedGrade (
    SchoolId uniqueidentifier NOT NULL,
    GradePublicationId uniqueidentifier NOT NULL,
    EnrollmentId uniqueidentifier NOT NULL,
    Score decimal(9,4) NULL,
    MaximumScore decimal(9,4) NULL,
    DescriptiveResult nvarchar(500) NULL,
    DetailsJson nvarchar(max) NOT NULL,
    CONSTRAINT PK_PublishedGrade PRIMARY KEY (SchoolId, GradePublicationId, EnrollmentId),
    CONSTRAINT FK_PublishedGrade_Publication FOREIGN KEY (SchoolId, GradePublicationId) REFERENCES assessment.GradePublication(SchoolId, GradePublicationId),
    CONSTRAINT FK_PublishedGrade_Enrollment FOREIGN KEY (SchoolId, EnrollmentId) REFERENCES people.StudentEnrollment(SchoolId, EnrollmentId),
    CONSTRAINT CK_PublishedGrade_Score CHECK (Score IS NULL OR (Score >= 0 AND MaximumScore > 0 AND Score <= MaximumScore)),
    CONSTRAINT CK_PublishedGrade_Json CHECK (ISJSON(DetailsJson)=1)
  );

  CREATE TABLE assessment.ReopenRequest (
    ReopenRequestId uniqueidentifier NOT NULL CONSTRAINT DF_ReopenRequest_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    GradebookId uniqueidentifier NOT NULL,
    RequestedByUserId uniqueidentifier NOT NULL,
    Reason nvarchar(2000) NOT NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_ReopenRequest_Status DEFAULT (''submitted''),
    DecidedByUserId uniqueidentifier NULL,
    DecisionNote nvarchar(2000) NULL,
    RequestedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_ReopenRequest_At DEFAULT SYSUTCDATETIME(),
    DecidedAtUtc datetime2(3) NULL,
    CONSTRAINT PK_ReopenRequest PRIMARY KEY CLUSTERED (ReopenRequestId),
    CONSTRAINT FK_ReopenRequest_Gradebook FOREIGN KEY (SchoolId, GradebookId) REFERENCES assessment.Gradebook(SchoolId, GradebookId),
    CONSTRAINT FK_ReopenRequest_Requester FOREIGN KEY (RequestedByUserId) REFERENCES security.UserAccount(UserId),
    CONSTRAINT FK_ReopenRequest_Decider FOREIGN KEY (DecidedByUserId) REFERENCES security.UserAccount(UserId),
    CONSTRAINT CK_ReopenRequest_Status CHECK (Status IN (''submitted'',''approved'',''rejected'',''withdrawn''))
  );

  CREATE TABLE assessment.Certificate (
    CertificateId uniqueidentifier NOT NULL CONSTRAINT DF_Certificate_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    GradePublicationId uniqueidentifier NOT NULL,
    EnrollmentId uniqueidentifier NOT NULL,
    Serial nvarchar(100) NOT NULL,
    VerificationTokenHash binary(32) NOT NULL,
    IssuedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_Certificate_Issued DEFAULT SYSUTCDATETIME(),
    RevokedAtUtc datetime2(3) NULL,
    RevocationReason nvarchar(1000) NULL,
    CONSTRAINT PK_Certificate PRIMARY KEY CLUSTERED (CertificateId),
    CONSTRAINT UQ_Certificate_Serial UNIQUE (SchoolId, Serial),
    CONSTRAINT FK_Certificate_Grade FOREIGN KEY (SchoolId, GradePublicationId, EnrollmentId) REFERENCES assessment.PublishedGrade(SchoolId, GradePublicationId, EnrollmentId),
    CONSTRAINT CK_Certificate_Revocation CHECK ((RevokedAtUtc IS NULL AND RevocationReason IS NULL) OR (RevokedAtUtc IS NOT NULL AND RevocationReason IS NOT NULL))
  );

  CREATE TABLE learning.Circular (
    CircularId uniqueidentifier NOT NULL CONSTRAINT DF_Circular_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    Title nvarchar(200) NOT NULL,
    Body nvarchar(max) NOT NULL,
    VersionNo int NOT NULL CONSTRAINT DF_Circular_Version DEFAULT (1),
    Status varchar(20) NOT NULL CONSTRAINT DF_Circular_Status DEFAULT (''draft''),
    CreatedByUserId uniqueidentifier NOT NULL,
    PublishedAtUtc datetime2(3) NULL,
    ExpiresOn date NULL,
    CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_Circular_Created DEFAULT SYSUTCDATETIME(),
    RowVersion rowversion NOT NULL,
    CONSTRAINT PK_Circular PRIMARY KEY CLUSTERED (CircularId),
    CONSTRAINT UQ_Circular_ScopeId UNIQUE (SchoolId, CircularId),
    CONSTRAINT FK_Circular_School FOREIGN KEY (SchoolId) REFERENCES core.School(SchoolId),
    CONSTRAINT FK_Circular_Creator FOREIGN KEY (CreatedByUserId) REFERENCES security.UserAccount(UserId),
    CONSTRAINT CK_Circular_Version CHECK (VersionNo > 0),
    CONSTRAINT CK_Circular_Status CHECK (Status IN (''draft'',''published'',''archived'',''cancelled''))
  );

  CREATE TABLE learning.CircularAudience (
    CircularAudienceId uniqueidentifier NOT NULL CONSTRAINT DF_CircularAudience_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    CircularId uniqueidentifier NOT NULL,
    AudienceType varchar(20) NOT NULL,
    GradeLevelId uniqueidentifier NULL,
    ClassSectionId uniqueidentifier NULL,
    CONSTRAINT PK_CircularAudience PRIMARY KEY CLUSTERED (CircularAudienceId),
    CONSTRAINT FK_CircularAudience_Circular FOREIGN KEY (SchoolId, CircularId) REFERENCES learning.Circular(SchoolId, CircularId),
    CONSTRAINT FK_CircularAudience_Grade FOREIGN KEY (SchoolId, GradeLevelId) REFERENCES academic.GradeLevel(SchoolId, GradeLevelId),
    CONSTRAINT FK_CircularAudience_Class FOREIGN KEY (SchoolId, ClassSectionId) REFERENCES academic.ClassSection(SchoolId, ClassSectionId),
    CONSTRAINT CK_CircularAudience_Type CHECK ((AudienceType IN (''all_school'',''role'') AND GradeLevelId IS NULL AND ClassSectionId IS NULL) OR (AudienceType=''grade'' AND GradeLevelId IS NOT NULL AND ClassSectionId IS NULL) OR (AudienceType=''class'' AND ClassSectionId IS NOT NULL AND GradeLevelId IS NULL))
  );

  CREATE TABLE learning.CircularAcknowledgement (
    SchoolId uniqueidentifier NOT NULL,
    CircularId uniqueidentifier NOT NULL,
    UserId uniqueidentifier NOT NULL,
    AcknowledgedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_CircularAck_At DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_CircularAcknowledgement PRIMARY KEY (SchoolId, CircularId, UserId),
    CONSTRAINT FK_CircularAck_Circular FOREIGN KEY (SchoolId, CircularId) REFERENCES learning.Circular(SchoolId, CircularId),
    CONSTRAINT FK_CircularAck_User FOREIGN KEY (UserId) REFERENCES security.UserAccount(UserId)
  );

  CREATE TABLE learning.Resource (
    ResourceId uniqueidentifier NOT NULL CONSTRAINT DF_Resource_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    SubjectId uniqueidentifier NULL,
    Title nvarchar(200) NOT NULL,
    Description nvarchar(2000) NULL,
    ResourceType varchar(30) NOT NULL,
    Visibility varchar(20) NOT NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_Resource_Status DEFAULT (''draft''),
    CreatedByUserId uniqueidentifier NOT NULL,
    PublishedAtUtc datetime2(3) NULL,
    CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_Resource_Created DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Resource PRIMARY KEY CLUSTERED (ResourceId),
    CONSTRAINT UQ_Resource_ScopeId UNIQUE (SchoolId, ResourceId),
    CONSTRAINT FK_Resource_School FOREIGN KEY (SchoolId) REFERENCES core.School(SchoolId),
    CONSTRAINT FK_Resource_Subject FOREIGN KEY (SchoolId, SubjectId) REFERENCES academic.Subject(SchoolId, SubjectId),
    CONSTRAINT FK_Resource_Creator FOREIGN KEY (CreatedByUserId) REFERENCES security.UserAccount(UserId),
    CONSTRAINT CK_Resource_Type CHECK (ResourceType IN (''book'',''document'',''video'',''link'',''worksheet'',''other'')),
    CONSTRAINT CK_Resource_Visibility CHECK (Visibility IN (''school'',''stage'',''grade'',''class'',''assignment'')),
    CONSTRAINT CK_Resource_Status CHECK (Status IN (''draft'',''published'',''archived''))
  );

  CREATE TABLE learning.ResourceFile (
    SchoolId uniqueidentifier NOT NULL,
    ResourceId uniqueidentifier NOT NULL,
    FileObjectId uniqueidentifier NOT NULL,
    SortOrder smallint NOT NULL CONSTRAINT DF_ResourceFile_Order DEFAULT (1),
    CONSTRAINT PK_ResourceFile PRIMARY KEY (SchoolId, ResourceId, FileObjectId),
    CONSTRAINT FK_ResourceFile_Resource FOREIGN KEY (SchoolId, ResourceId) REFERENCES learning.Resource(SchoolId, ResourceId),
    CONSTRAINT FK_ResourceFile_File FOREIGN KEY (SchoolId, FileObjectId) REFERENCES core.FileObject(SchoolId, FileObjectId),
    CONSTRAINT CK_ResourceFile_Order CHECK (SortOrder > 0)
  );

  CREATE INDEX IX_AttendanceSession_ClassDate ON attendance.AttendanceSession(SchoolId, ClassSectionId, SessionDate DESC, Status);
  CREATE INDEX IX_StudentAttendance_Enrollment ON attendance.StudentAttendance(SchoolId, EnrollmentId, AttendanceSessionId) INCLUDE (StatusCode);
  CREATE INDEX IX_LeaveRequest_EmployeeStatusDate ON attendance.LeaveRequest(SchoolId, EmployeeId, Status, StartDate, EndDate);
  CREATE INDEX IX_Assignment_TeachingDue ON learning.Assignment(SchoolId, TeachingAssignmentId, DueAtLocal, Status);
  CREATE INDEX IX_Submission_AssignmentStatus ON learning.Submission(SchoolId, AssignmentId, Status) INCLUDE (EnrollmentId, CurrentRevisionNo);
  CREATE INDEX IX_Gradebook_Status ON assessment.Gradebook(SchoolId, Status, CreatedAtUtc DESC);
  CREATE INDEX IX_GradeItem_Enrollment ON assessment.GradeItem(SchoolId, EnrollmentId, GradebookId);
  CREATE INDEX IX_Circular_Published ON learning.Circular(SchoolId, PublishedAtUtc DESC) WHERE Status=''published'';

  
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
  THROW;
END CATCH;
';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(3,N''003_learning_assessment.sql'',0x6fee9880e52f2384f484f38f8f78ea20eceef450d6678c10853651dde351b39f,''executed'');';
 -- BEGIN 004_operations.sql
 EXEC sys.sp_executesql N'SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;';
 EXEC sys.sp_executesql N'
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY
  
  IF SCHEMA_ID(N''finance'') IS NULL EXEC(N''CREATE SCHEMA finance AUTHORIZATION dbo'');
  IF SCHEMA_ID(N''transport'') IS NULL EXEC(N''CREATE SCHEMA transport AUTHORIZATION dbo'');
  IF SCHEMA_ID(N''hr'') IS NULL EXEC(N''CREATE SCHEMA hr AUTHORIZATION dbo'');
  IF SCHEMA_ID(N''admissions'') IS NULL EXEC(N''CREATE SCHEMA admissions AUTHORIZATION dbo'');
  IF SCHEMA_ID(N''health'') IS NULL EXEC(N''CREATE SCHEMA health AUTHORIZATION dbo'');
  IF SCHEMA_ID(N''operations'') IS NULL EXEC(N''CREATE SCHEMA operations AUTHORIZATION dbo'');

  CREATE TABLE finance.StudentFeeAccount (
    StudentFeeAccountId uniqueidentifier NOT NULL CONSTRAINT DF_FeeAccount_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    StudentId uniqueidentifier NOT NULL,
    SchoolYearId uniqueidentifier NOT NULL,
    CurrencyCode char(3) NOT NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_FeeAccount_Status DEFAULT (''active''),
    CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_FeeAccount_Created DEFAULT SYSUTCDATETIME(),
    RowVersion rowversion NOT NULL,
    CONSTRAINT PK_StudentFeeAccount PRIMARY KEY CLUSTERED (StudentFeeAccountId),
    CONSTRAINT UQ_FeeAccount_StudentYear UNIQUE (SchoolId, StudentId, SchoolYearId),
    CONSTRAINT UQ_FeeAccount_ScopeId UNIQUE (SchoolId, StudentFeeAccountId),
    CONSTRAINT FK_FeeAccount_Student FOREIGN KEY (SchoolId, StudentId) REFERENCES people.StudentProfile(SchoolId, StudentId),
    CONSTRAINT FK_FeeAccount_Year FOREIGN KEY (SchoolId, SchoolYearId) REFERENCES core.SchoolYear(SchoolId, SchoolYearId),
    CONSTRAINT CK_FeeAccount_Currency CHECK (CurrencyCode LIKE ''[A-Z][A-Z][A-Z]''),
    CONSTRAINT CK_FeeAccount_Status CHECK (Status IN (''active'',''closed'',''suspended''))
  );

  CREATE TABLE finance.FeeItem (
    FeeItemId uniqueidentifier NOT NULL CONSTRAINT DF_FeeItem_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    Code nvarchar(40) NOT NULL,
    Name nvarchar(160) NOT NULL,
    Description nvarchar(500) NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_FeeItem_Status DEFAULT (''active''),
    CONSTRAINT PK_FeeItem PRIMARY KEY CLUSTERED (FeeItemId),
    CONSTRAINT UQ_FeeItem_ScopeCode UNIQUE (SchoolId, Code),
    CONSTRAINT UQ_FeeItem_ScopeId UNIQUE (SchoolId, FeeItemId),
    CONSTRAINT FK_FeeItem_School FOREIGN KEY (SchoolId) REFERENCES core.School(SchoolId),
    CONSTRAINT CK_FeeItem_Status CHECK (Status IN (''active'',''inactive'',''archived''))
  );

  CREATE TABLE finance.Charge (
    ChargeId uniqueidentifier NOT NULL CONSTRAINT DF_Charge_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    StudentFeeAccountId uniqueidentifier NOT NULL,
    FeeItemId uniqueidentifier NOT NULL,
    Amount decimal(19,4) NOT NULL,
    CurrencyCode char(3) NOT NULL,
    DueDate date NOT NULL,
    Description nvarchar(500) NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_Charge_Status DEFAULT (''open''),
    CreatedByUserId uniqueidentifier NOT NULL,
    CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_Charge_Created DEFAULT SYSUTCDATETIME(),
    RowVersion rowversion NOT NULL,
    CONSTRAINT PK_Charge PRIMARY KEY CLUSTERED (ChargeId),
    CONSTRAINT UQ_Charge_ScopeId UNIQUE (SchoolId, ChargeId),
    CONSTRAINT FK_Charge_Account FOREIGN KEY (SchoolId, StudentFeeAccountId) REFERENCES finance.StudentFeeAccount(SchoolId, StudentFeeAccountId),
    CONSTRAINT FK_Charge_FeeItem FOREIGN KEY (SchoolId, FeeItemId) REFERENCES finance.FeeItem(SchoolId, FeeItemId),
    CONSTRAINT FK_Charge_Creator FOREIGN KEY (CreatedByUserId) REFERENCES security.UserAccount(UserId),
    CONSTRAINT CK_Charge_Amount CHECK (Amount >= 0),
    CONSTRAINT CK_Charge_Currency CHECK (CurrencyCode LIKE ''[A-Z][A-Z][A-Z]''),
    CONSTRAINT CK_Charge_Status CHECK (Status IN (''open'',''partially_paid'',''paid'',''waived'',''cancelled'',''reversed''))
  );

  CREATE TABLE finance.ChargeAdjustment (
    ChargeAdjustmentId uniqueidentifier NOT NULL CONSTRAINT DF_ChargeAdjustment_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    ChargeId uniqueidentifier NOT NULL,
    AdjustmentType varchar(20) NOT NULL,
    Amount decimal(19,4) NOT NULL,
    Reason nvarchar(1000) NOT NULL,
    ApprovedByUserId uniqueidentifier NOT NULL,
    CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_ChargeAdjustment_Created DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_ChargeAdjustment PRIMARY KEY CLUSTERED (ChargeAdjustmentId),
    CONSTRAINT FK_ChargeAdjustment_Charge FOREIGN KEY (SchoolId, ChargeId) REFERENCES finance.Charge(SchoolId, ChargeId),
    CONSTRAINT FK_ChargeAdjustment_Approver FOREIGN KEY (ApprovedByUserId) REFERENCES security.UserAccount(UserId),
    CONSTRAINT CK_ChargeAdjustment_Type CHECK (AdjustmentType IN (''discount'',''scholarship'',''waiver'',''debit_correction'',''credit_correction'')),
    CONSTRAINT CK_ChargeAdjustment_Amount CHECK (Amount > 0)
  );

  CREATE TABLE finance.Installment (
    InstallmentId uniqueidentifier NOT NULL CONSTRAINT DF_Installment_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    ChargeId uniqueidentifier NOT NULL,
    SequenceNo smallint NOT NULL,
    DueDate date NOT NULL,
    Amount decimal(19,4) NOT NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_Installment_Status DEFAULT (''due''),
    CONSTRAINT PK_Installment PRIMARY KEY CLUSTERED (InstallmentId),
    CONSTRAINT UQ_Installment_Sequence UNIQUE (SchoolId, ChargeId, SequenceNo),
    CONSTRAINT UQ_Installment_ScopeId UNIQUE (SchoolId, InstallmentId),
    CONSTRAINT FK_Installment_Charge FOREIGN KEY (SchoolId, ChargeId) REFERENCES finance.Charge(SchoolId, ChargeId),
    CONSTRAINT CK_Installment_Sequence CHECK (SequenceNo > 0),
    CONSTRAINT CK_Installment_Amount CHECK (Amount > 0),
    CONSTRAINT CK_Installment_Status CHECK (Status IN (''due'',''partially_paid'',''paid'',''cancelled''))
  );

  CREATE TABLE finance.PaymentAttempt (
    PaymentAttemptId uniqueidentifier NOT NULL CONSTRAINT DF_PaymentAttempt_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    InstallmentId uniqueidentifier NOT NULL,
    ProviderCode varchar(60) NOT NULL,
    IdempotencyKey nvarchar(150) NOT NULL,
    Amount decimal(19,4) NOT NULL,
    CurrencyCode char(3) NOT NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_PaymentAttempt_Status DEFAULT (''created''),
    ProviderReference nvarchar(200) NULL,
    CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_PaymentAttempt_Created DEFAULT SYSUTCDATETIME(),
    CompletedAtUtc datetime2(3) NULL,
    RowVersion rowversion NOT NULL,
    CONSTRAINT PK_PaymentAttempt PRIMARY KEY CLUSTERED (PaymentAttemptId),
    CONSTRAINT UQ_PaymentAttempt_Idempotency UNIQUE (SchoolId, ProviderCode, IdempotencyKey),
    CONSTRAINT UQ_PaymentAttempt_ScopeId UNIQUE (SchoolId, PaymentAttemptId),
    CONSTRAINT FK_PaymentAttempt_Installment FOREIGN KEY (SchoolId, InstallmentId) REFERENCES finance.Installment(SchoolId, InstallmentId),
    CONSTRAINT CK_PaymentAttempt_Amount CHECK (Amount > 0),
    CONSTRAINT CK_PaymentAttempt_Status CHECK (Status IN (''created'',''pending'',''authorized'',''settled'',''failed'',''cancelled'',''refunded''))
  );

  CREATE TABLE finance.Payment (
    PaymentId uniqueidentifier NOT NULL CONSTRAINT DF_Payment_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    PaymentAttemptId uniqueidentifier NOT NULL,
    Amount decimal(19,4) NOT NULL,
    CurrencyCode char(3) NOT NULL,
    ProviderReference nvarchar(200) NULL,
    SettledAtUtc datetime2(3) NOT NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_Payment_Status DEFAULT (''settled''),
    CONSTRAINT PK_Payment PRIMARY KEY CLUSTERED (PaymentId),
    CONSTRAINT UQ_Payment_Attempt UNIQUE (SchoolId, PaymentAttemptId),
    CONSTRAINT UQ_Payment_ScopeId UNIQUE (SchoolId, PaymentId),
    CONSTRAINT FK_Payment_Attempt FOREIGN KEY (SchoolId, PaymentAttemptId) REFERENCES finance.PaymentAttempt(SchoolId, PaymentAttemptId),
    CONSTRAINT CK_Payment_Amount CHECK (Amount > 0),
    CONSTRAINT CK_Payment_Status CHECK (Status IN (''settled'',''partially_refunded'',''refunded'',''reversed''))
  );

  CREATE TABLE finance.PaymentReversal (
    PaymentReversalId uniqueidentifier NOT NULL CONSTRAINT DF_PaymentReversal_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    PaymentId uniqueidentifier NOT NULL,
    Amount decimal(19,4) NOT NULL,
    Reason nvarchar(1000) NOT NULL,
    ExternalReference nvarchar(200) NULL,
    ApprovedByUserId uniqueidentifier NOT NULL,
    ReversedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_PaymentReversal_At DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_PaymentReversal PRIMARY KEY CLUSTERED (PaymentReversalId),
    CONSTRAINT FK_PaymentReversal_Payment FOREIGN KEY (SchoolId, PaymentId) REFERENCES finance.Payment(SchoolId, PaymentId),
    CONSTRAINT FK_PaymentReversal_Approver FOREIGN KEY (ApprovedByUserId) REFERENCES security.UserAccount(UserId),
    CONSTRAINT CK_PaymentReversal_Amount CHECK (Amount > 0)
  );

  CREATE TABLE finance.Receipt (
    ReceiptId uniqueidentifier NOT NULL CONSTRAINT DF_Receipt_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    PaymentId uniqueidentifier NOT NULL,
    Serial nvarchar(100) NOT NULL,
    VerificationTokenHash binary(32) NOT NULL,
    IssuedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_Receipt_Issued DEFAULT SYSUTCDATETIME(),
    VoidedAtUtc datetime2(3) NULL,
    VoidReason nvarchar(1000) NULL,
    CONSTRAINT PK_Receipt PRIMARY KEY CLUSTERED (ReceiptId),
    CONSTRAINT UQ_Receipt_Payment UNIQUE (SchoolId, PaymentId),
    CONSTRAINT UQ_Receipt_Serial UNIQUE (SchoolId, Serial),
    CONSTRAINT FK_Receipt_Payment FOREIGN KEY (SchoolId, PaymentId) REFERENCES finance.Payment(SchoolId, PaymentId),
    CONSTRAINT CK_Receipt_Void CHECK ((VoidedAtUtc IS NULL AND VoidReason IS NULL) OR (VoidedAtUtc IS NOT NULL AND VoidReason IS NOT NULL))
  );

  CREATE TABLE transport.Vehicle (
    VehicleId uniqueidentifier NOT NULL CONSTRAINT DF_Vehicle_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    RegistrationNo nvarchar(50) NOT NULL,
    Capacity smallint NOT NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_Vehicle_Status DEFAULT (''active''),
    CONSTRAINT PK_Vehicle PRIMARY KEY CLUSTERED (VehicleId),
    CONSTRAINT UQ_Vehicle_SchoolRegistration UNIQUE (SchoolId, RegistrationNo),
    CONSTRAINT UQ_Vehicle_ScopeId UNIQUE (SchoolId, VehicleId),
    CONSTRAINT FK_Vehicle_School FOREIGN KEY (SchoolId) REFERENCES core.School(SchoolId),
    CONSTRAINT CK_Vehicle_Capacity CHECK (Capacity > 0),
    CONSTRAINT CK_Vehicle_Status CHECK (Status IN (''active'',''maintenance'',''inactive'',''retired''))
  );

  CREATE TABLE transport.Route (
    RouteId uniqueidentifier NOT NULL CONSTRAINT DF_Route_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    Code nvarchar(40) NOT NULL,
    Name nvarchar(160) NOT NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_Route_Status DEFAULT (''active''),
    CONSTRAINT PK_Route PRIMARY KEY CLUSTERED (RouteId),
    CONSTRAINT UQ_Route_SchoolCode UNIQUE (SchoolId, Code),
    CONSTRAINT UQ_Route_ScopeId UNIQUE (SchoolId, RouteId),
    CONSTRAINT FK_Route_School FOREIGN KEY (SchoolId) REFERENCES core.School(SchoolId),
    CONSTRAINT CK_Route_Status CHECK (Status IN (''active'',''inactive'',''archived''))
  );

  CREATE TABLE transport.RouteStop (
    RouteStopId uniqueidentifier NOT NULL CONSTRAINT DF_RouteStop_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    RouteId uniqueidentifier NOT NULL,
    SequenceNo smallint NOT NULL,
    Name nvarchar(160) NOT NULL,
    Latitude decimal(9,6) NULL,
    Longitude decimal(9,6) NULL,
    PlannedArrival time(0) NULL,
    CONSTRAINT PK_RouteStop PRIMARY KEY CLUSTERED (RouteStopId),
    CONSTRAINT UQ_RouteStop_Sequence UNIQUE (SchoolId, RouteId, SequenceNo),
    CONSTRAINT UQ_RouteStop_ScopeId UNIQUE (SchoolId, RouteId, RouteStopId),
    CONSTRAINT FK_RouteStop_Route FOREIGN KEY (SchoolId, RouteId) REFERENCES transport.Route(SchoolId, RouteId),
    CONSTRAINT CK_RouteStop_Sequence CHECK (SequenceNo > 0),
    CONSTRAINT CK_RouteStop_Latitude CHECK (Latitude IS NULL OR Latitude BETWEEN -90 AND 90),
    CONSTRAINT CK_RouteStop_Longitude CHECK (Longitude IS NULL OR Longitude BETWEEN -180 AND 180)
  );

  CREATE TABLE transport.TransportEnrollment (
    TransportEnrollmentId uniqueidentifier NOT NULL CONSTRAINT DF_TransportEnrollment_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    StudentEnrollmentId uniqueidentifier NOT NULL,
    RouteId uniqueidentifier NOT NULL,
    PickupRouteStopId uniqueidentifier NOT NULL,
    DropoffRouteStopId uniqueidentifier NOT NULL,
    ValidFrom date NOT NULL,
    ValidTo date NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_TransportEnrollment_Status DEFAULT (''active''),
    CONSTRAINT PK_TransportEnrollment PRIMARY KEY CLUSTERED (TransportEnrollmentId),
    CONSTRAINT UQ_TransportEnrollment_ScopeId UNIQUE (SchoolId, TransportEnrollmentId),
    CONSTRAINT FK_TransportEnrollment_Student FOREIGN KEY (SchoolId, StudentEnrollmentId) REFERENCES people.StudentEnrollment(SchoolId, EnrollmentId),
    CONSTRAINT FK_TransportEnrollment_Route FOREIGN KEY (SchoolId, RouteId) REFERENCES transport.Route(SchoolId, RouteId),
    CONSTRAINT FK_TransportEnrollment_Pickup FOREIGN KEY (SchoolId, RouteId, PickupRouteStopId) REFERENCES transport.RouteStop(SchoolId, RouteId, RouteStopId),
    CONSTRAINT FK_TransportEnrollment_Dropoff FOREIGN KEY (SchoolId, RouteId, DropoffRouteStopId) REFERENCES transport.RouteStop(SchoolId, RouteId, RouteStopId),
    CONSTRAINT CK_TransportEnrollment_Dates CHECK (ValidTo IS NULL OR ValidFrom <= ValidTo),
    CONSTRAINT CK_TransportEnrollment_Status CHECK (Status IN (''active'',''paused'',''ended''))
  );

  CREATE TABLE transport.RouteRun (
    RouteRunId uniqueidentifier NOT NULL CONSTRAINT DF_RouteRun_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    RouteId uniqueidentifier NOT NULL,
    VehicleId uniqueidentifier NOT NULL,
    DriverEmployeeId uniqueidentifier NOT NULL,
    RunDate date NOT NULL,
    Direction varchar(20) NOT NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_RouteRun_Status DEFAULT (''scheduled''),
    StartedAtUtc datetime2(3) NULL,
    CompletedAtUtc datetime2(3) NULL,
    CONSTRAINT PK_RouteRun PRIMARY KEY CLUSTERED (RouteRunId),
    CONSTRAINT UQ_RouteRun_ScopeId UNIQUE (SchoolId, RouteRunId),
    CONSTRAINT FK_RouteRun_Route FOREIGN KEY (SchoolId, RouteId) REFERENCES transport.Route(SchoolId, RouteId),
    CONSTRAINT FK_RouteRun_Vehicle FOREIGN KEY (SchoolId, VehicleId) REFERENCES transport.Vehicle(SchoolId, VehicleId),
    CONSTRAINT FK_RouteRun_Driver FOREIGN KEY (SchoolId, DriverEmployeeId) REFERENCES people.EmployeeProfile(SchoolId, EmployeeId),
    CONSTRAINT CK_RouteRun_Direction CHECK (Direction IN (''morning'',''afternoon'')),
    CONSTRAINT CK_RouteRun_Status CHECK (Status IN (''scheduled'',''in_progress'',''completed'',''cancelled'')),
    CONSTRAINT CK_RouteRun_Times CHECK (CompletedAtUtc IS NULL OR StartedAtUtc IS NULL OR StartedAtUtc <= CompletedAtUtc)
  );

  CREATE TABLE transport.RideNotice (
    RideNoticeId uniqueidentifier NOT NULL CONSTRAINT DF_RideNotice_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    TransportEnrollmentId uniqueidentifier NOT NULL,
    NoticeDate date NOT NULL,
    Direction varchar(20) NOT NULL,
    Reason nvarchar(500) NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_RideNotice_Status DEFAULT (''active''),
    CreatedByUserId uniqueidentifier NOT NULL,
    CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_RideNotice_Created DEFAULT SYSUTCDATETIME(),
    CancelledAtUtc datetime2(3) NULL,
    CONSTRAINT PK_RideNotice PRIMARY KEY CLUSTERED (RideNoticeId),
    CONSTRAINT FK_RideNotice_Enrollment FOREIGN KEY (SchoolId, TransportEnrollmentId) REFERENCES transport.TransportEnrollment(SchoolId, TransportEnrollmentId),
    CONSTRAINT FK_RideNotice_User FOREIGN KEY (CreatedByUserId) REFERENCES security.UserAccount(UserId),
    CONSTRAINT CK_RideNotice_Direction CHECK (Direction IN (''morning'',''afternoon'',''both'')),
    CONSTRAINT CK_RideNotice_Status CHECK (Status IN (''active'',''cancelled'',''processed''))
  );
  CREATE UNIQUE INDEX UX_RideNotice_ActiveDay ON transport.RideNotice(SchoolId, TransportEnrollmentId, NoticeDate) WHERE Status=''active'';

  CREATE TABLE hr.EmploymentContract (
    EmploymentContractId uniqueidentifier NOT NULL CONSTRAINT DF_EmploymentContract_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    EmployeeId uniqueidentifier NOT NULL,
    ContractNumber nvarchar(80) NOT NULL,
    ContractType varchar(30) NOT NULL,
    StartDate date NOT NULL,
    EndDate date NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_EmploymentContract_Status DEFAULT (''draft''),
    DocumentFileObjectId uniqueidentifier NULL,
    RowVersion rowversion NOT NULL,
    CONSTRAINT PK_EmploymentContract PRIMARY KEY CLUSTERED (EmploymentContractId),
    CONSTRAINT UQ_EmploymentContract_Number UNIQUE (SchoolId, ContractNumber),
    CONSTRAINT FK_EmploymentContract_Employee FOREIGN KEY (SchoolId, EmployeeId) REFERENCES people.EmployeeProfile(SchoolId, EmployeeId),
    CONSTRAINT FK_EmploymentContract_File FOREIGN KEY (SchoolId, DocumentFileObjectId) REFERENCES core.FileObject(SchoolId, FileObjectId),
    CONSTRAINT CK_EmploymentContract_Dates CHECK (EndDate IS NULL OR StartDate <= EndDate),
    CONSTRAINT CK_EmploymentContract_Status CHECK (Status IN (''draft'',''active'',''expired'',''terminated'',''archived''))
  );

  CREATE TABLE hr.PayrollRun (
    PayrollRunId uniqueidentifier NOT NULL CONSTRAINT DF_PayrollRun_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    PeriodStart date NOT NULL,
    PeriodEnd date NOT NULL,
    RunNo smallint NOT NULL CONSTRAINT DF_PayrollRun_No DEFAULT (1),
    CurrencyCode char(3) NOT NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_PayrollRun_Status DEFAULT (''draft''),
    ApprovedByUserId uniqueidentifier NULL,
    ApprovedAtUtc datetime2(3) NULL,
    CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_PayrollRun_Created DEFAULT SYSUTCDATETIME(),
    RowVersion rowversion NOT NULL,
    CONSTRAINT PK_PayrollRun PRIMARY KEY CLUSTERED (PayrollRunId),
    CONSTRAINT UQ_PayrollRun_Period UNIQUE (SchoolId, PeriodStart, PeriodEnd, RunNo),
    CONSTRAINT UQ_PayrollRun_ScopeId UNIQUE (SchoolId, PayrollRunId),
    CONSTRAINT FK_PayrollRun_School FOREIGN KEY (SchoolId) REFERENCES core.School(SchoolId),
    CONSTRAINT FK_PayrollRun_Approver FOREIGN KEY (ApprovedByUserId) REFERENCES security.UserAccount(UserId),
    CONSTRAINT CK_PayrollRun_Dates CHECK (PeriodStart <= PeriodEnd),
    CONSTRAINT CK_PayrollRun_RunNo CHECK (RunNo > 0),
    CONSTRAINT CK_PayrollRun_Status CHECK (Status IN (''draft'',''calculated'',''submitted'',''approved'',''paid'',''cancelled''))
  );

  CREATE TABLE hr.PayrollRunLine (
    PayrollRunLineId uniqueidentifier NOT NULL CONSTRAINT DF_PayrollLine_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    PayrollRunId uniqueidentifier NOT NULL,
    EmployeeId uniqueidentifier NOT NULL,
    GrossAmount decimal(19,4) NOT NULL,
    DeductionAmount decimal(19,4) NOT NULL,
    NetAmount decimal(19,4) NOT NULL,
    CurrencyCode char(3) NOT NULL,
    BreakdownJson nvarchar(max) NOT NULL,
    CONSTRAINT PK_PayrollRunLine PRIMARY KEY CLUSTERED (PayrollRunLineId),
    CONSTRAINT UQ_PayrollRunLine_Employee UNIQUE (SchoolId, PayrollRunId, EmployeeId),
    CONSTRAINT FK_PayrollLine_Run FOREIGN KEY (SchoolId, PayrollRunId) REFERENCES hr.PayrollRun(SchoolId, PayrollRunId),
    CONSTRAINT FK_PayrollLine_Employee FOREIGN KEY (SchoolId, EmployeeId) REFERENCES people.EmployeeProfile(SchoolId, EmployeeId),
    CONSTRAINT CK_PayrollLine_Amounts CHECK (GrossAmount >= 0 AND DeductionAmount >= 0 AND NetAmount = GrossAmount - DeductionAmount),
    CONSTRAINT CK_PayrollLine_Json CHECK (ISJSON(BreakdownJson)=1)
  );

  CREATE TABLE admissions.Application (
    ApplicationId uniqueidentifier NOT NULL CONSTRAINT DF_Application_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    ApplicationNumber nvarchar(80) NOT NULL,
    ApplicantPersonId uniqueidentifier NOT NULL,
    SchoolYearId uniqueidentifier NOT NULL,
    DesiredGradeLevelId uniqueidentifier NOT NULL,
    Status varchar(25) NOT NULL CONSTRAINT DF_Application_Status DEFAULT (''submitted''),
    SubmittedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_Application_Submitted DEFAULT SYSUTCDATETIME(),
    RowVersion rowversion NOT NULL,
    CONSTRAINT PK_Application PRIMARY KEY CLUSTERED (ApplicationId),
    CONSTRAINT UQ_Application_Number UNIQUE (SchoolId, ApplicationNumber),
    CONSTRAINT UQ_Application_ScopeId UNIQUE (SchoolId, ApplicationId),
    CONSTRAINT FK_Application_School FOREIGN KEY (SchoolId) REFERENCES core.School(SchoolId),
    CONSTRAINT FK_Application_Person FOREIGN KEY (ApplicantPersonId) REFERENCES people.Person(PersonId),
    CONSTRAINT FK_Application_Year FOREIGN KEY (SchoolId, SchoolYearId) REFERENCES core.SchoolYear(SchoolId, SchoolYearId),
    CONSTRAINT FK_Application_Grade FOREIGN KEY (SchoolId, DesiredGradeLevelId) REFERENCES academic.GradeLevel(SchoolId, GradeLevelId),
    CONSTRAINT CK_Application_Status CHECK (Status IN (''draft'',''submitted'',''under_review'',''waitlisted'',''accepted'',''rejected'',''withdrawn'',''enrolled''))
  );

  CREATE TABLE admissions.ApplicationDecision (
    ApplicationDecisionId uniqueidentifier NOT NULL CONSTRAINT DF_ApplicationDecision_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    ApplicationId uniqueidentifier NOT NULL,
    ActorUserId uniqueidentifier NOT NULL,
    Decision varchar(25) NOT NULL,
    Reason nvarchar(2000) NULL,
    OccurredAtUtc datetime2(3) NOT NULL CONSTRAINT DF_ApplicationDecision_At DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_ApplicationDecision PRIMARY KEY CLUSTERED (ApplicationDecisionId),
    CONSTRAINT FK_ApplicationDecision_Application FOREIGN KEY (SchoolId, ApplicationId) REFERENCES admissions.Application(SchoolId, ApplicationId),
    CONSTRAINT FK_ApplicationDecision_Actor FOREIGN KEY (ActorUserId) REFERENCES security.UserAccount(UserId),
    CONSTRAINT CK_ApplicationDecision_Decision CHECK (Decision IN (''under_review'',''waitlisted'',''accepted'',''rejected'',''withdrawn''))
  );

  CREATE TABLE health.ClinicEncounter (
    ClinicEncounterId uniqueidentifier NOT NULL CONSTRAINT DF_ClinicEncounter_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    StudentId uniqueidentifier NOT NULL,
    ClinicianUserId uniqueidentifier NOT NULL,
    OccurredAtUtc datetime2(3) NOT NULL,
    Symptoms nvarchar(2000) NULL,
    Assessment nvarchar(2000) NULL,
    ActionTaken nvarchar(2000) NULL,
    RestrictedFlag bit NOT NULL CONSTRAINT DF_ClinicEncounter_Restricted DEFAULT (1),
    CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_ClinicEncounter_Created DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_ClinicEncounter PRIMARY KEY CLUSTERED (ClinicEncounterId),
    CONSTRAINT FK_ClinicEncounter_Student FOREIGN KEY (SchoolId, StudentId) REFERENCES people.StudentProfile(SchoolId, StudentId),
    CONSTRAINT FK_ClinicEncounter_Clinician FOREIGN KEY (ClinicianUserId) REFERENCES security.UserAccount(UserId)
  );

  CREATE TABLE operations.Incident (
    IncidentId uniqueidentifier NOT NULL CONSTRAINT DF_Incident_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    OccurredAtUtc datetime2(3) NOT NULL,
    CategoryCode varchar(50) NOT NULL,
    Severity varchar(20) NOT NULL,
    Summary nvarchar(2000) NOT NULL,
    FollowUp nvarchar(3000) NULL,
    Confidentiality varchar(20) NOT NULL CONSTRAINT DF_Incident_Confidentiality DEFAULT (''restricted''),
    Status varchar(20) NOT NULL CONSTRAINT DF_Incident_Status DEFAULT (''open''),
    ReportedByUserId uniqueidentifier NOT NULL,
    CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_Incident_Created DEFAULT SYSUTCDATETIME(),
    RowVersion rowversion NOT NULL,
    CONSTRAINT PK_Incident PRIMARY KEY CLUSTERED (IncidentId),
    CONSTRAINT UQ_Incident_ScopeId UNIQUE (SchoolId, IncidentId),
    CONSTRAINT FK_Incident_School FOREIGN KEY (SchoolId) REFERENCES core.School(SchoolId),
    CONSTRAINT FK_Incident_Reporter FOREIGN KEY (ReportedByUserId) REFERENCES security.UserAccount(UserId),
    CONSTRAINT CK_Incident_Severity CHECK (Severity IN (''low'',''medium'',''high'',''critical'')),
    CONSTRAINT CK_Incident_Confidentiality CHECK (Confidentiality IN (''school'',''restricted'',''highly_restricted'')),
    CONSTRAINT CK_Incident_Status CHECK (Status IN (''open'',''investigating'',''follow_up'',''resolved'',''closed''))
  );

  CREATE TABLE operations.IncidentParty (
    IncidentId uniqueidentifier NOT NULL,
    SchoolId uniqueidentifier NOT NULL,
    PersonId uniqueidentifier NOT NULL,
    PartyRole varchar(30) NOT NULL,
    Notes nvarchar(1000) NULL,
    CONSTRAINT PK_IncidentParty PRIMARY KEY (SchoolId, IncidentId, PersonId, PartyRole),
    CONSTRAINT FK_IncidentParty_Incident FOREIGN KEY (SchoolId, IncidentId) REFERENCES operations.Incident(SchoolId, IncidentId),
    CONSTRAINT FK_IncidentParty_Person FOREIGN KEY (PersonId) REFERENCES people.Person(PersonId),
    CONSTRAINT CK_IncidentParty_Role CHECK (PartyRole IN (''reported_by'',''student'',''employee'',''guardian'',''witness'',''other''))
  );

  CREATE TABLE operations.ImportJob (
    ImportJobId uniqueidentifier NOT NULL CONSTRAINT DF_ImportJob_Id DEFAULT NEWSEQUENTIALID(),
    SchoolId uniqueidentifier NOT NULL,
    SourceSystem nvarchar(60) NOT NULL,
    EntityType nvarchar(80) NOT NULL,
    FileName nvarchar(255) NOT NULL,
    FileHash binary(32) NOT NULL,
    Status varchar(20) NOT NULL CONSTRAINT DF_ImportJob_Status DEFAULT (''queued''),
    TotalRows int NOT NULL,
    ImportedRows int NOT NULL CONSTRAINT DF_ImportJob_Imported DEFAULT (0),
    RejectedRows int NOT NULL CONSTRAINT DF_ImportJob_Rejected DEFAULT (0),
    CreatedByUserId uniqueidentifier NOT NULL,
    CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_ImportJob_Created DEFAULT SYSUTCDATETIME(),
    CompletedAtUtc datetime2(3) NULL,
    RowVersion rowversion NOT NULL,
    CONSTRAINT PK_ImportJob PRIMARY KEY CLUSTERED (ImportJobId),
    CONSTRAINT UQ_ImportJob_Fingerprint UNIQUE (SchoolId, SourceSystem, EntityType, FileHash),
    CONSTRAINT UQ_ImportJob_ScopeId UNIQUE (SchoolId, ImportJobId),
    CONSTRAINT FK_ImportJob_School FOREIGN KEY (SchoolId) REFERENCES core.School(SchoolId),
    CONSTRAINT FK_ImportJob_Creator FOREIGN KEY (CreatedByUserId) REFERENCES security.UserAccount(UserId),
    CONSTRAINT CK_ImportJob_Status CHECK (Status IN (''queued'',''validating'',''ready'',''processing'',''completed'',''completed_with_errors'',''failed'',''cancelled'')),
    CONSTRAINT CK_ImportJob_Counts CHECK (TotalRows >= 0 AND ImportedRows >= 0 AND RejectedRows >= 0 AND ImportedRows + RejectedRows <= TotalRows)
  );

  CREATE TABLE operations.ImportRowError (
    ImportRowErrorId bigint IDENTITY(1,1) NOT NULL,
    SchoolId uniqueidentifier NOT NULL,
    ImportJobId uniqueidentifier NOT NULL,
    RowNumber int NOT NULL,
    FieldName nvarchar(120) NULL,
    ErrorCode varchar(100) NOT NULL,
    SafeMessage nvarchar(1000) NOT NULL,
    RawValueHash binary(32) NULL,
    CONSTRAINT PK_ImportRowError PRIMARY KEY CLUSTERED (ImportRowErrorId),
    CONSTRAINT FK_ImportRowError_Job FOREIGN KEY (SchoolId, ImportJobId) REFERENCES operations.ImportJob(SchoolId, ImportJobId),
    CONSTRAINT CK_ImportRowError_Row CHECK (RowNumber > 0)
  );

  CREATE INDEX IX_Charge_AccountDue ON finance.Charge(SchoolId, StudentFeeAccountId, DueDate, Status) INCLUDE (FeeItemId, Amount, CurrencyCode);
  CREATE INDEX IX_Installment_DueStatus ON finance.Installment(SchoolId, DueDate, Status) INCLUDE (ChargeId, Amount);
  CREATE INDEX IX_PaymentAttempt_StatusCreated ON finance.PaymentAttempt(SchoolId, Status, CreatedAtUtc);
  CREATE INDEX IX_RouteRun_DateStatus ON transport.RouteRun(SchoolId, RunDate, Status, Direction);
  CREATE INDEX IX_PayrollRun_PeriodStatus ON hr.PayrollRun(SchoolId, PeriodStart, PeriodEnd, Status);
  CREATE INDEX IX_Application_StatusSubmitted ON admissions.Application(SchoolId, Status, SubmittedAtUtc DESC);
  CREATE INDEX IX_ClinicEncounter_StudentTime ON health.ClinicEncounter(SchoolId, StudentId, OccurredAtUtc DESC);
  CREATE INDEX IX_Incident_StatusTime ON operations.Incident(SchoolId, Status, OccurredAtUtc DESC);
  CREATE INDEX IX_ImportRowError_JobRow ON operations.ImportRowError(SchoolId, ImportJobId, RowNumber);

  
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
  THROW;
END CATCH;
';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(4,N''004_operations.sql'',0x11fc11fd5c3cb44a97fe6300d2292dc9b7ee78d79e874105ea1ad500ab358304,''executed'');';
 -- BEGIN 005_seed_reference_data.sql
 EXEC sys.sp_executesql N'SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;';
 EXEC sys.sp_executesql N'
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY
  
  IF OBJECT_ID(N''security.Role'', N''U'') IS NULL OR OBJECT_ID(N''security.Permission'', N''U'') IS NULL
    THROW 51000, ''Apply core identity migration before reference data.'', 1;

  INSERT INTO security.Role (Code, Name, IsSystemRole)
  SELECT seed.Code, seed.Name, 1
  FROM (VALUES
    (''platform_owner'', N''مالك المنصة''),
    (''admin'', N''مسؤول النظام''),
    (''principal'', N''مدير المدرسة''),
    (''supervisor'', N''المشرف التربوي''),
    (''teacher'', N''المعلم''),
    (''student'', N''الطالب''),
    (''parent'', N''ولي الأمر''),
    (''finance_officer'', N''مسؤول المالية''),
    (''hr_officer'', N''مسؤول الموارد البشرية''),
    (''clinic_staff'', N''الطاقم الصحي''),
    (''admissions_officer'', N''مسؤول القبول''),
    (''transport_officer'', N''مسؤول النقل'')
  ) AS seed(Code, Name)
  WHERE NOT EXISTS (SELECT 1 FROM security.Role existing WHERE existing.Code=seed.Code);

  INSERT INTO security.Permission (Code, Description)
  SELECT seed.Code, seed.Description
  FROM (VALUES
    (''school.read'', N''عرض بيانات المدرسة''),
    (''school.manage'', N''إدارة إعدادات المدرسة''),
    (''users.read'', N''عرض حسابات المستخدمين''),
    (''users.manage'', N''إنشاء وتعديل الحسابات''),
    (''security.roles.manage'', N''إسناد الأدوار والصلاحيات''),
    (''students.read'', N''عرض سجلات الطلبة''),
    (''students.manage'', N''إدارة ملفات الطلبة وتسجيلهم''),
    (''guardians.manage'', N''إدارة روابط أولياء الأمور والتفويض''),
    (''attendance.read'', N''عرض الحضور''),
    (''attendance.record'', N''تسجيل الحضور''),
    (''leave.request'', N''إنشاء طلب إجازة''),
    (''leave.decide'', N''اتخاذ قرار في طلب الإجازة''),
    (''assignments.read'', N''عرض الواجبات''),
    (''assignments.submit'', N''تسليم الواجبات''),
    (''assignments.manage'', N''إدارة الواجبات والتصحيح''),
    (''grades.read'', N''عرض النتائج المنشورة''),
    (''grades.enter'', N''إدخال العلامات''),
    (''grades.review'', N''تدقيق العلامات''),
    (''grades.publish'', N''اعتماد ونشر العلامات''),
    (''grades.reopen'', N''طلب أو اعتماد إعادة فتح العلامات''),
    (''finance.read'', N''عرض الحسابات المالية''),
    (''finance.manage'', N''إدارة الرسوم والدفعات''),
    (''payroll.read'', N''عرض الرواتب''),
    (''payroll.manage'', N''إدارة الرواتب''),
    (''transport.manage'', N''إدارة النقل والأسطول''),
    (''clinic.read'', N''عرض السجلات الطبية المقيدة''),
    (''clinic.manage'', N''إدارة السجلات الطبية المقيدة''),
    (''communications.manage'', N''إدارة التعاميم والمراسلات''),
    (''communications.read'', N''عرض التعاميم الموجهة''),
    (''audit.read'', N''عرض سجل التدقيق''),
    (''imports.manage'', N''إدارة استيراد وتصدير البيانات'')
  ) AS seed(Code, Description)
  WHERE NOT EXISTS (SELECT 1 FROM security.Permission existing WHERE existing.Code=seed.Code);

  INSERT INTO security.RolePermission (RoleId, PermissionId)
  SELECT role.RoleId, permission.PermissionId
  FROM (VALUES
    (''platform_owner'',''school.read''),(''platform_owner'',''users.read''),(''platform_owner'',''audit.read''),
    (''admin'',''users.read''),(''admin'',''users.manage''),(''admin'',''security.roles.manage''),(''admin'',''school.read''),(''admin'',''school.manage''),(''admin'',''audit.read''),(''admin'',''imports.manage''),
    (''principal'',''school.read''),(''principal'',''students.read''),(''principal'',''students.manage''),(''principal'',''guardians.manage''),(''principal'',''attendance.read''),(''principal'',''leave.decide''),(''principal'',''grades.review''),(''principal'',''grades.publish''),(''principal'',''grades.reopen''),(''principal'',''communications.manage''),(''principal'',''audit.read''),
    (''supervisor'',''school.read''),(''supervisor'',''students.read''),(''supervisor'',''grades.review''),(''supervisor'',''communications.manage''),
    (''teacher'',''students.read''),(''teacher'',''attendance.read''),(''teacher'',''attendance.record''),(''teacher'',''leave.request''),(''teacher'',''assignments.manage''),(''teacher'',''grades.enter''),(''teacher'',''communications.manage''),
    (''student'',''assignments.read''),(''student'',''assignments.submit''),(''student'',''grades.read''),
    (''parent'',''attendance.read''),(''parent'',''grades.read''),(''parent'',''finance.read''),(''parent'',''communications.read''),
    (''finance_officer'',''finance.read''),(''finance_officer'',''finance.manage''),
    (''hr_officer'',''payroll.read''),(''hr_officer'',''payroll.manage''),
    (''clinic_staff'',''clinic.read''),(''clinic_staff'',''clinic.manage''),
    (''admissions_officer'',''students.read''),(''admissions_officer'',''students.manage''),
    (''transport_officer'',''students.read''),(''transport_officer'',''transport.manage'')
  ) AS seed(RoleCode, PermissionCode)
  INNER JOIN security.Role role ON role.Code=seed.RoleCode
  INNER JOIN security.Permission permission ON permission.Code=seed.PermissionCode
  WHERE NOT EXISTS (SELECT 1 FROM security.RolePermission existing WHERE existing.RoleId=role.RoleId AND existing.PermissionId=permission.PermissionId);

  
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
  THROW;
END CATCH;
';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(5,N''005_seed_reference_data.sql'',0xa4317edd7f4f8c037bffe9d249bc26ed0f05fb654c03c72c5362f94856763cdf,''executed'');';
 -- BEGIN 006_business_invariants.sql
 EXEC sys.sp_executesql N'SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;';
 EXEC sys.sp_executesql N'
SET NOCOUNT ON;
SET XACT_ABORT ON;
-- Additive business invariants. Existing invalid records stop the migration.
IF DB_NAME() NOT IN (N''Awn'',N''Awn_InstallValidation_20261030'',N''Awn_BusinessRulesValidation_20261030'')
 THROW 51100, ''Select an authorized Awn database before applying migration 006.'', 1;
BEGIN TRY
 
 IF EXISTS(SELECT 1 FROM core.AcademicTerm t JOIN core.SchoolYear y ON y.SchoolId=t.SchoolId AND y.SchoolYearId=t.SchoolYearId WHERE t.StartDate<y.StartDate OR t.EndDate>y.EndDate)
  THROW 51101, ''Existing terms fall outside their school year.'',1;
 IF EXISTS(SELECT 1 FROM people.StudentEnrollment WHERE Status=''active'' GROUP BY SchoolId,StudentId,SchoolYearId HAVING COUNT(*)>1)
  THROW 51102, ''Existing duplicate active enrollments require review.'',1;
 IF EXISTS(SELECT 1 FROM finance.Charge c JOIN finance.StudentFeeAccount a ON a.SchoolId=c.SchoolId AND a.StudentFeeAccountId=c.StudentFeeAccountId WHERE c.CurrencyCode<>a.CurrencyCode)
  THROW 51103, ''Existing charge/account currencies do not match.'',1;
 IF EXISTS(SELECT 1 FROM assessment.GradingPolicy p OUTER APPLY (SELECT COUNT(*) AS N,COUNT(WeightPercent) AS W,SUM(WeightPercent) AS Total FROM assessment.GradingComponent c WHERE c.SchoolId=p.SchoolId AND c.GradingPolicyId=p.GradingPolicyId) w WHERE p.Status=''approved'' AND p.AssessmentMode=''weighted'' AND (w.N=0 OR w.N<>w.W OR w.Total<>100))
  THROW 51104, ''Existing approved weighted policies must total 100.'',1;
 IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N''people.StudentEnrollment'') AND name=N''UX_Enrollment_OneActiveStudentYear'')
  CREATE UNIQUE INDEX UX_Enrollment_OneActiveStudentYear ON people.StudentEnrollment(SchoolId,StudentId,SchoolYearId) WHERE Status=''active'';
 IF NOT EXISTS(SELECT 1 FROM sys.key_constraints WHERE parent_object_id=OBJECT_ID(N''finance.StudentFeeAccount'') AND name=N''UQ_FeeAccount_ScopeCurrency'')
  ALTER TABLE finance.StudentFeeAccount ADD CONSTRAINT UQ_FeeAccount_ScopeCurrency UNIQUE(SchoolId,StudentFeeAccountId,CurrencyCode);
 IF NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE parent_object_id=OBJECT_ID(N''finance.Charge'') AND name=N''FK_Charge_AccountCurrency'')
  ALTER TABLE finance.Charge WITH CHECK ADD CONSTRAINT FK_Charge_AccountCurrency FOREIGN KEY(SchoolId,StudentFeeAccountId,CurrencyCode) REFERENCES finance.StudentFeeAccount(SchoolId,StudentFeeAccountId,CurrencyCode);
 EXEC(N''CREATE OR ALTER TRIGGER core.TR_AcademicTerm_YearBounds ON core.AcademicTerm AFTER INSERT, UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted t JOIN core.SchoolYear y WITH (UPDLOCK,HOLDLOCK) ON y.SchoolId=t.SchoolId AND y.SchoolYearId=t.SchoolYearId WHERE t.StartDate<y.StartDate OR t.EndDate>y.EndDate)
 THROW 51111, ''''Academic term must be contained within its school year.'''',1;
END;'');
 EXEC(N''CREATE OR ALTER TRIGGER core.TR_SchoolYear_TermBounds ON core.SchoolYear AFTER UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted y JOIN core.AcademicTerm t WITH (UPDLOCK,HOLDLOCK) ON t.SchoolId=y.SchoolId AND t.SchoolYearId=y.SchoolYearId WHERE t.StartDate<y.StartDate OR t.EndDate>y.EndDate)
 THROW 51112, ''''School year dates cannot exclude an existing term.'''',1;
END;'');
 EXEC(N''CREATE OR ALTER TRIGGER assessment.TR_GradingPolicy_ApprovedWeights ON assessment.GradingPolicy AFTER INSERT, UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted p OUTER APPLY (SELECT COUNT(*) AS N,COUNT(WeightPercent) AS W,SUM(WeightPercent) AS Total FROM assessment.GradingComponent c WITH (UPDLOCK,HOLDLOCK) WHERE c.SchoolId=p.SchoolId AND c.GradingPolicyId=p.GradingPolicyId) w WHERE p.Status=''''approved'''' AND p.AssessmentMode=''''weighted'''' AND (w.N=0 OR w.N<>w.W OR w.Total<>100))
 THROW 51113, ''''Approved weighted policies require non-null component weights totaling exactly 100.'''',1;
END;'');
 EXEC(N''CREATE OR ALTER TRIGGER assessment.TR_GradingComponent_ApprovedWeights ON assessment.GradingComponent AFTER INSERT, UPDATE, DELETE AS
BEGIN
 SET NOCOUNT ON;
 -- Lock all affected parent policies, including both sides of a component move.
DECLARE @locked uniqueidentifier;
SELECT @locked=p.GradingPolicyId FROM assessment.GradingPolicy p WITH (UPDLOCK,HOLDLOCK)
JOIN (SELECT SchoolId,GradingPolicyId FROM inserted UNION SELECT SchoolId,GradingPolicyId FROM deleted) a ON a.SchoolId=p.SchoolId AND a.GradingPolicyId=p.GradingPolicyId;
IF EXISTS(SELECT 1 FROM assessment.GradingPolicy p JOIN (SELECT SchoolId,GradingPolicyId FROM inserted UNION SELECT SchoolId,GradingPolicyId FROM deleted) a ON a.SchoolId=p.SchoolId AND a.GradingPolicyId=p.GradingPolicyId
OUTER APPLY (SELECT COUNT(*) AS N,COUNT(WeightPercent) AS W,SUM(WeightPercent) AS Total FROM assessment.GradingComponent c WITH (UPDLOCK,HOLDLOCK) WHERE c.SchoolId=p.SchoolId AND c.GradingPolicyId=p.GradingPolicyId) w
WHERE p.Status=''''approved'''' AND p.AssessmentMode=''''weighted'''' AND (w.N=0 OR w.N<>w.W OR w.Total<>100))
 THROW 51114, ''''Component changes cannot invalidate an approved weighted policy.'''',1;
END;'');
 
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(6,N''006_business_invariants.sql'',0x32bdd0f75c1214eded6a4b1c96c7e98106b424b150657c3f2c71511ae85ba1bb,''executed'');';
 -- BEGIN 007_reference_integrity.sql
 EXEC sys.sp_executesql N'SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF DB_NAME() NOT IN (N''Awn'',N''Awn_DeliveryRestore_20261030'',N''Awn_ReleaseAuditUtf8_20261030'',N''Awn_InstallValidation_20261030'',N''Awn_BusinessRulesValidation_20261030'')
 THROW 51400, ''Select an authorized Awn database before migration 007.'',1;
BEGIN TRY
 
 -- Remove only the three obsolete default grants identified by the audit.
 DELETE rp FROM security.RolePermission rp
 JOIN security.Role r ON r.RoleId=rp.RoleId
 JOIN security.Permission p ON p.PermissionId=rp.PermissionId
 WHERE (r.Code=''student'' AND p.Code IN (''assignments.manage'',''grades.enter''))
 OR (r.Code=''parent'' AND p.Code=''communications.manage'');
 IF NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE name=''FK_Room_School'')
  ALTER TABLE academic.Room WITH CHECK ADD CONSTRAINT FK_Room_School FOREIGN KEY(SchoolId) REFERENCES core.School(SchoolId);
 -- Platform events may omit both IDs; school events must include their organization.
 IF NOT EXISTS(SELECT 1 FROM sys.check_constraints WHERE name=''CK_AuditEvent_SchoolOrganization'')
  ALTER TABLE audit.AuditEvent WITH CHECK ADD CONSTRAINT CK_AuditEvent_SchoolOrganization CHECK(SchoolId IS NULL OR OrganizationId IS NOT NULL);
 IF NOT EXISTS(SELECT 1 FROM sys.key_constraints WHERE name=''UQ_TeachingAssignment_ScopeTerm'')
  ALTER TABLE academic.TeachingAssignment ADD CONSTRAINT UQ_TeachingAssignment_ScopeTerm UNIQUE(SchoolId,SchoolYearId,TermId,TeachingAssignmentId);
 IF NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE name=''FK_TimetableLesson_AssignmentTerm'')
  ALTER TABLE academic.TimetableLesson WITH CHECK ADD CONSTRAINT FK_TimetableLesson_AssignmentTerm FOREIGN KEY(SchoolId,SchoolYearId,TermId,TeachingAssignmentId) REFERENCES academic.TeachingAssignment(SchoolId,SchoolYearId,TermId,TeachingAssignmentId);
 IF NOT EXISTS(SELECT 1 FROM sys.check_constraints WHERE name=''CK_PublishedGrade_NumericMaximum'')
  ALTER TABLE assessment.PublishedGrade WITH CHECK ADD CONSTRAINT CK_PublishedGrade_NumericMaximum CHECK(Score IS NULL OR MaximumScore IS NOT NULL);
 
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(7,N''007_reference_integrity.sql'',0xa561dda5b48dcafb3ba7fd8ce728f1e80bee11337fc73cbe9c2de68c01fb2e5f,''executed'');';
 -- BEGIN 008_domain_integrity.sql
 EXEC sys.sp_executesql N'-- Generated from scripts/database/domain-rules.cjs. Rules protect child and parent writes.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
SET XACT_ABORT ON;
SET NOCOUNT ON;
BEGIN TRY
 
 IF EXISTS(SELECT 1 FROM assessment.GradeItem x WITH (UPDLOCK,HOLDLOCK) JOIN assessment.GradingComponent c WITH (UPDLOCK,HOLDLOCK) ON c.GradingComponentId=x.GradingComponentId AND c.SchoolId=x.SchoolId WHERE (x.Score IS NOT NULL AND (c.MaximumScore IS NULL OR x.Score>c.MaximumScore))) THROW 51500, ''GradeScore: existing data violates the invariant.'',1;
 IF EXISTS(SELECT 1 FROM assessment.GradeItem x WITH (UPDLOCK,HOLDLOCK) JOIN assessment.GradingComponent c WITH (UPDLOCK,HOLDLOCK) ON c.GradingComponentId=x.GradingComponentId JOIN assessment.Gradebook b WITH (UPDLOCK,HOLDLOCK) ON b.GradebookId=x.GradebookId WHERE (c.GradingPolicyId<>b.GradingPolicyId)) THROW 51501, ''GradePolicy: existing data violates the invariant.'',1;
 IF EXISTS(SELECT 1 FROM assessment.GradeItem x WITH (UPDLOCK,HOLDLOCK) JOIN assessment.Gradebook b WITH (UPDLOCK,HOLDLOCK) ON b.GradebookId=x.GradebookId JOIN academic.TeachingAssignment a WITH (UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=b.TeachingAssignmentId JOIN people.StudentEnrollment e WITH (UPDLOCK,HOLDLOCK) ON e.EnrollmentId=x.EnrollmentId WHERE (a.ClassSectionId<>e.ClassSectionId OR a.SchoolYearId<>e.SchoolYearId)) THROW 51502, ''GradeEnrollment: existing data violates the invariant.'',1;
 IF EXISTS(SELECT 1 FROM assessment.Gradebook x WITH (UPDLOCK,HOLDLOCK) JOIN assessment.GradingPolicy p WITH (UPDLOCK,HOLDLOCK) ON p.GradingPolicyId=x.GradingPolicyId JOIN academic.TeachingAssignment a WITH (UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=x.TeachingAssignmentId JOIN academic.ClassSection c WITH (UPDLOCK,HOLDLOCK) ON c.ClassSectionId=a.ClassSectionId JOIN academic.GradeLevel g WITH (UPDLOCK,HOLDLOCK) ON g.GradeLevelId=c.GradeLevelId WHERE (p.SchoolYearId<>a.SchoolYearId OR p.TermId<>a.TermId OR p.StageId<>g.StageId OR (p.GradeLevelId IS NOT NULL AND p.GradeLevelId<>c.GradeLevelId) OR (p.SubjectId IS NOT NULL AND p.SubjectId<>a.SubjectId))) THROW 51503, ''BookPolicyScope: existing data violates the invariant.'',1;
 IF EXISTS(SELECT 1 FROM learning.Submission x WITH (UPDLOCK,HOLDLOCK) JOIN learning.Assignment w WITH (UPDLOCK,HOLDLOCK) ON w.AssignmentId=x.AssignmentId JOIN academic.TeachingAssignment a WITH (UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=w.TeachingAssignmentId JOIN people.StudentEnrollment e WITH (UPDLOCK,HOLDLOCK) ON e.EnrollmentId=x.EnrollmentId WHERE (a.ClassSectionId<>e.ClassSectionId OR a.SchoolYearId<>e.SchoolYearId)) THROW 51504, ''SubmissionEnrollment: existing data violates the invariant.'',1;
 IF EXISTS(SELECT 1 FROM learning.SubmissionRevision x WITH (UPDLOCK,HOLDLOCK) JOIN learning.Submission s WITH (UPDLOCK,HOLDLOCK) ON s.SubmissionId=x.SubmissionId JOIN learning.Assignment a WITH (UPDLOCK,HOLDLOCK) ON a.AssignmentId=s.AssignmentId WHERE (x.Score>a.MaximumScore)) THROW 51505, ''SubmissionScore: existing data violates the invariant.'',1;
 IF EXISTS(SELECT 1 FROM attendance.StudentAttendance x WITH (UPDLOCK,HOLDLOCK) JOIN attendance.AttendanceSession s WITH (UPDLOCK,HOLDLOCK) ON s.AttendanceSessionId=x.AttendanceSessionId JOIN people.StudentEnrollment e WITH (UPDLOCK,HOLDLOCK) ON e.EnrollmentId=x.EnrollmentId WHERE (s.SessionType=''employee_shift'' OR (s.ClassSectionId IS NOT NULL AND s.ClassSectionId<>e.ClassSectionId) OR s.SessionDate<e.StartDate OR s.SessionDate>COALESCE(e.EndDate,CONVERT(date,''99991231'')))) THROW 51506, ''AttendanceEnrollment: existing data violates the invariant.'',1;
 IF EXISTS(SELECT 1 FROM people.StudentEnrollment x WITH (UPDLOCK,HOLDLOCK) JOIN core.SchoolYear y WITH (UPDLOCK,HOLDLOCK) ON y.SchoolYearId=x.SchoolYearId WHERE (x.StartDate<y.StartDate OR x.StartDate>y.EndDate OR (x.EndDate IS NOT NULL AND x.EndDate>y.EndDate))) THROW 51507, ''EnrollmentDates: existing data violates the invariant.'',1;
 IF EXISTS(SELECT 1 FROM finance.PaymentAttempt x WITH (UPDLOCK,HOLDLOCK) JOIN finance.Installment i WITH (UPDLOCK,HOLDLOCK) ON i.InstallmentId=x.InstallmentId JOIN finance.Charge c WITH (UPDLOCK,HOLDLOCK) ON c.ChargeId=i.ChargeId WHERE (x.CurrencyCode<>c.CurrencyCode)) THROW 51508, ''AttemptCurrency: existing data violates the invariant.'',1;
 IF EXISTS(SELECT 1 FROM finance.Payment x WITH (UPDLOCK,HOLDLOCK) JOIN finance.PaymentAttempt a WITH (UPDLOCK,HOLDLOCK) ON a.PaymentAttemptId=x.PaymentAttemptId WHERE (x.CurrencyCode<>a.CurrencyCode OR x.Amount<>a.Amount OR a.Status NOT IN (''settled'',''refunded''))) THROW 51509, ''PaymentSettlement: existing data violates the invariant.'',1;
 IF EXISTS(SELECT 1 FROM finance.Payment x WITH (UPDLOCK,HOLDLOCK) CROSS APPLY(SELECT SUM(r.Amount) total FROM finance.PaymentReversal r WITH (UPDLOCK,HOLDLOCK) WHERE r.SchoolId=x.SchoolId AND r.PaymentId=x.PaymentId) r WHERE (r.total>x.Amount)) THROW 51510, ''ReversalTotal: existing data violates the invariant.'',1;
 IF EXISTS(SELECT 1 FROM finance.Charge x WITH (UPDLOCK,HOLDLOCK) OUTER APPLY(SELECT SUM(CASE WHEN a.AdjustmentType=''debit_correction'' THEN a.Amount ELSE -a.Amount END) total FROM finance.ChargeAdjustment a WITH (UPDLOCK,HOLDLOCK) WHERE a.SchoolId=x.SchoolId AND a.ChargeId=x.ChargeId) a OUTER APPLY(SELECT SUM(i.Amount) total FROM finance.Installment i WITH (UPDLOCK,HOLDLOCK) WHERE i.SchoolId=x.SchoolId AND i.ChargeId=x.ChargeId AND i.Status<>''cancelled'') i WHERE (x.Amount+COALESCE(a.total,0)<0 OR COALESCE(i.total,0)>x.Amount+COALESCE(a.total,0))) THROW 51511, ''InstallmentBudget: existing data violates the invariant.'',1;
 IF EXISTS(SELECT 1 FROM finance.Installment x WITH (UPDLOCK,HOLDLOCK) OUTER APPLY(SELECT SUM(p.Amount-COALESCE(r.total,0)) total FROM finance.PaymentAttempt a WITH (UPDLOCK,HOLDLOCK) JOIN finance.Payment p WITH (UPDLOCK,HOLDLOCK) ON p.PaymentAttemptId=a.PaymentAttemptId OUTER APPLY(SELECT SUM(r.Amount) total FROM finance.PaymentReversal r WITH (UPDLOCK,HOLDLOCK) WHERE r.SchoolId=p.SchoolId AND r.PaymentId=p.PaymentId) r WHERE a.SchoolId=x.SchoolId AND a.InstallmentId=x.InstallmentId) p WHERE (COALESCE(p.total,0)>x.Amount OR (x.Status=''cancelled'' AND COALESCE(p.total,0)>0))) THROW 51512, ''InstallmentSettlement: existing data violates the invariant.'',1;
 IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(''attendance.AttendanceSession'') AND name=''UX_AttendanceSession_Identity'')
 CREATE UNIQUE INDEX UX_AttendanceSession_Identity ON attendance.AttendanceSession(SchoolId,SessionType,SessionDate,ClassSectionId,PeriodId) WHERE Status<>''cancelled'';
 EXEC(N''CREATE OR ALTER TRIGGER academic.TR_ClassSection_DomainIntegrity ON academic.ClassSection AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Schools table(SchoolId uniqueidentifier PRIMARY KEY);
 INSERT @Schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
 IF EXISTS(SELECT 1 FROM assessment.Gradebook x WITH (UPDLOCK,HOLDLOCK) JOIN assessment.GradingPolicy p WITH (UPDLOCK,HOLDLOCK) ON p.GradingPolicyId=x.GradingPolicyId JOIN academic.TeachingAssignment a WITH (UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=x.TeachingAssignmentId JOIN academic.ClassSection c WITH (UPDLOCK,HOLDLOCK) ON c.ClassSectionId=a.ClassSectionId JOIN academic.GradeLevel g WITH (UPDLOCK,HOLDLOCK) ON g.GradeLevelId=c.GradeLevelId WHERE (p.SchoolYearId<>a.SchoolYearId OR p.TermId<>a.TermId OR p.StageId<>g.StageId OR (p.GradeLevelId IS NOT NULL AND p.GradeLevelId<>c.GradeLevelId) OR (p.SubjectId IS NOT NULL AND p.SubjectId<>a.SubjectId)) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51503, ''''BookPolicyScope: operation violates the invariant.'''',1;
END;'');
 EXEC(N''CREATE OR ALTER TRIGGER academic.TR_GradeLevel_DomainIntegrity ON academic.GradeLevel AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Schools table(SchoolId uniqueidentifier PRIMARY KEY);
 INSERT @Schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
 IF EXISTS(SELECT 1 FROM assessment.Gradebook x WITH (UPDLOCK,HOLDLOCK) JOIN assessment.GradingPolicy p WITH (UPDLOCK,HOLDLOCK) ON p.GradingPolicyId=x.GradingPolicyId JOIN academic.TeachingAssignment a WITH (UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=x.TeachingAssignmentId JOIN academic.ClassSection c WITH (UPDLOCK,HOLDLOCK) ON c.ClassSectionId=a.ClassSectionId JOIN academic.GradeLevel g WITH (UPDLOCK,HOLDLOCK) ON g.GradeLevelId=c.GradeLevelId WHERE (p.SchoolYearId<>a.SchoolYearId OR p.TermId<>a.TermId OR p.StageId<>g.StageId OR (p.GradeLevelId IS NOT NULL AND p.GradeLevelId<>c.GradeLevelId) OR (p.SubjectId IS NOT NULL AND p.SubjectId<>a.SubjectId)) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51503, ''''BookPolicyScope: operation violates the invariant.'''',1;
END;'');
 EXEC(N''CREATE OR ALTER TRIGGER academic.TR_TeachingAssignment_DomainIntegrity ON academic.TeachingAssignment AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Schools table(SchoolId uniqueidentifier PRIMARY KEY);
 INSERT @Schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
 IF EXISTS(SELECT 1 FROM assessment.GradeItem x WITH (UPDLOCK,HOLDLOCK) JOIN assessment.Gradebook b WITH (UPDLOCK,HOLDLOCK) ON b.GradebookId=x.GradebookId JOIN academic.TeachingAssignment a WITH (UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=b.TeachingAssignmentId JOIN people.StudentEnrollment e WITH (UPDLOCK,HOLDLOCK) ON e.EnrollmentId=x.EnrollmentId WHERE (a.ClassSectionId<>e.ClassSectionId OR a.SchoolYearId<>e.SchoolYearId) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51502, ''''GradeEnrollment: operation violates the invariant.'''',1;
 IF EXISTS(SELECT 1 FROM assessment.Gradebook x WITH (UPDLOCK,HOLDLOCK) JOIN assessment.GradingPolicy p WITH (UPDLOCK,HOLDLOCK) ON p.GradingPolicyId=x.GradingPolicyId JOIN academic.TeachingAssignment a WITH (UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=x.TeachingAssignmentId JOIN academic.ClassSection c WITH (UPDLOCK,HOLDLOCK) ON c.ClassSectionId=a.ClassSectionId JOIN academic.GradeLevel g WITH (UPDLOCK,HOLDLOCK) ON g.GradeLevelId=c.GradeLevelId WHERE (p.SchoolYearId<>a.SchoolYearId OR p.TermId<>a.TermId OR p.StageId<>g.StageId OR (p.GradeLevelId IS NOT NULL AND p.GradeLevelId<>c.GradeLevelId) OR (p.SubjectId IS NOT NULL AND p.SubjectId<>a.SubjectId)) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51503, ''''BookPolicyScope: operation violates the invariant.'''',1;
 IF EXISTS(SELECT 1 FROM learning.Submission x WITH (UPDLOCK,HOLDLOCK) JOIN learning.Assignment w WITH (UPDLOCK,HOLDLOCK) ON w.AssignmentId=x.AssignmentId JOIN academic.TeachingAssignment a WITH (UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=w.TeachingAssignmentId JOIN people.StudentEnrollment e WITH (UPDLOCK,HOLDLOCK) ON e.EnrollmentId=x.EnrollmentId WHERE (a.ClassSectionId<>e.ClassSectionId OR a.SchoolYearId<>e.SchoolYearId) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51504, ''''SubmissionEnrollment: operation violates the invariant.'''',1;
END;'');
 EXEC(N''CREATE OR ALTER TRIGGER assessment.TR_GradeItem_DomainIntegrity ON assessment.GradeItem AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Schools table(SchoolId uniqueidentifier PRIMARY KEY);
 INSERT @Schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
 IF EXISTS(SELECT 1 FROM assessment.GradeItem x WITH (UPDLOCK,HOLDLOCK) JOIN assessment.GradingComponent c WITH (UPDLOCK,HOLDLOCK) ON c.GradingComponentId=x.GradingComponentId AND c.SchoolId=x.SchoolId WHERE (x.Score IS NOT NULL AND (c.MaximumScore IS NULL OR x.Score>c.MaximumScore)) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51500, ''''GradeScore: operation violates the invariant.'''',1;
 IF EXISTS(SELECT 1 FROM assessment.GradeItem x WITH (UPDLOCK,HOLDLOCK) JOIN assessment.GradingComponent c WITH (UPDLOCK,HOLDLOCK) ON c.GradingComponentId=x.GradingComponentId JOIN assessment.Gradebook b WITH (UPDLOCK,HOLDLOCK) ON b.GradebookId=x.GradebookId WHERE (c.GradingPolicyId<>b.GradingPolicyId) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51501, ''''GradePolicy: operation violates the invariant.'''',1;
 IF EXISTS(SELECT 1 FROM assessment.GradeItem x WITH (UPDLOCK,HOLDLOCK) JOIN assessment.Gradebook b WITH (UPDLOCK,HOLDLOCK) ON b.GradebookId=x.GradebookId JOIN academic.TeachingAssignment a WITH (UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=b.TeachingAssignmentId JOIN people.StudentEnrollment e WITH (UPDLOCK,HOLDLOCK) ON e.EnrollmentId=x.EnrollmentId WHERE (a.ClassSectionId<>e.ClassSectionId OR a.SchoolYearId<>e.SchoolYearId) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51502, ''''GradeEnrollment: operation violates the invariant.'''',1;
END;'');
 EXEC(N''CREATE OR ALTER TRIGGER assessment.TR_Gradebook_DomainIntegrity ON assessment.Gradebook AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Schools table(SchoolId uniqueidentifier PRIMARY KEY);
 INSERT @Schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
 IF EXISTS(SELECT 1 FROM assessment.GradeItem x WITH (UPDLOCK,HOLDLOCK) JOIN assessment.GradingComponent c WITH (UPDLOCK,HOLDLOCK) ON c.GradingComponentId=x.GradingComponentId JOIN assessment.Gradebook b WITH (UPDLOCK,HOLDLOCK) ON b.GradebookId=x.GradebookId WHERE (c.GradingPolicyId<>b.GradingPolicyId) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51501, ''''GradePolicy: operation violates the invariant.'''',1;
 IF EXISTS(SELECT 1 FROM assessment.GradeItem x WITH (UPDLOCK,HOLDLOCK) JOIN assessment.Gradebook b WITH (UPDLOCK,HOLDLOCK) ON b.GradebookId=x.GradebookId JOIN academic.TeachingAssignment a WITH (UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=b.TeachingAssignmentId JOIN people.StudentEnrollment e WITH (UPDLOCK,HOLDLOCK) ON e.EnrollmentId=x.EnrollmentId WHERE (a.ClassSectionId<>e.ClassSectionId OR a.SchoolYearId<>e.SchoolYearId) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51502, ''''GradeEnrollment: operation violates the invariant.'''',1;
 IF EXISTS(SELECT 1 FROM assessment.Gradebook x WITH (UPDLOCK,HOLDLOCK) JOIN assessment.GradingPolicy p WITH (UPDLOCK,HOLDLOCK) ON p.GradingPolicyId=x.GradingPolicyId JOIN academic.TeachingAssignment a WITH (UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=x.TeachingAssignmentId JOIN academic.ClassSection c WITH (UPDLOCK,HOLDLOCK) ON c.ClassSectionId=a.ClassSectionId JOIN academic.GradeLevel g WITH (UPDLOCK,HOLDLOCK) ON g.GradeLevelId=c.GradeLevelId WHERE (p.SchoolYearId<>a.SchoolYearId OR p.TermId<>a.TermId OR p.StageId<>g.StageId OR (p.GradeLevelId IS NOT NULL AND p.GradeLevelId<>c.GradeLevelId) OR (p.SubjectId IS NOT NULL AND p.SubjectId<>a.SubjectId)) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51503, ''''BookPolicyScope: operation violates the invariant.'''',1;
END;'');
 EXEC(N''CREATE OR ALTER TRIGGER assessment.TR_GradingComponent_DomainIntegrity ON assessment.GradingComponent AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Schools table(SchoolId uniqueidentifier PRIMARY KEY);
 INSERT @Schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
 IF EXISTS(SELECT 1 FROM assessment.GradeItem x WITH (UPDLOCK,HOLDLOCK) JOIN assessment.GradingComponent c WITH (UPDLOCK,HOLDLOCK) ON c.GradingComponentId=x.GradingComponentId AND c.SchoolId=x.SchoolId WHERE (x.Score IS NOT NULL AND (c.MaximumScore IS NULL OR x.Score>c.MaximumScore)) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51500, ''''GradeScore: operation violates the invariant.'''',1;
 IF EXISTS(SELECT 1 FROM assessment.GradeItem x WITH (UPDLOCK,HOLDLOCK) JOIN assessment.GradingComponent c WITH (UPDLOCK,HOLDLOCK) ON c.GradingComponentId=x.GradingComponentId JOIN assessment.Gradebook b WITH (UPDLOCK,HOLDLOCK) ON b.GradebookId=x.GradebookId WHERE (c.GradingPolicyId<>b.GradingPolicyId) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51501, ''''GradePolicy: operation violates the invariant.'''',1;
END;'');
 EXEC(N''CREATE OR ALTER TRIGGER assessment.TR_GradingPolicy_DomainIntegrity ON assessment.GradingPolicy AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Schools table(SchoolId uniqueidentifier PRIMARY KEY);
 INSERT @Schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
 IF EXISTS(SELECT 1 FROM assessment.Gradebook x WITH (UPDLOCK,HOLDLOCK) JOIN assessment.GradingPolicy p WITH (UPDLOCK,HOLDLOCK) ON p.GradingPolicyId=x.GradingPolicyId JOIN academic.TeachingAssignment a WITH (UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=x.TeachingAssignmentId JOIN academic.ClassSection c WITH (UPDLOCK,HOLDLOCK) ON c.ClassSectionId=a.ClassSectionId JOIN academic.GradeLevel g WITH (UPDLOCK,HOLDLOCK) ON g.GradeLevelId=c.GradeLevelId WHERE (p.SchoolYearId<>a.SchoolYearId OR p.TermId<>a.TermId OR p.StageId<>g.StageId OR (p.GradeLevelId IS NOT NULL AND p.GradeLevelId<>c.GradeLevelId) OR (p.SubjectId IS NOT NULL AND p.SubjectId<>a.SubjectId)) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51503, ''''BookPolicyScope: operation violates the invariant.'''',1;
END;'');
 EXEC(N''CREATE OR ALTER TRIGGER attendance.TR_AttendanceSession_DomainIntegrity ON attendance.AttendanceSession AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Schools table(SchoolId uniqueidentifier PRIMARY KEY);
 INSERT @Schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
 IF EXISTS(SELECT 1 FROM attendance.StudentAttendance x WITH (UPDLOCK,HOLDLOCK) JOIN attendance.AttendanceSession s WITH (UPDLOCK,HOLDLOCK) ON s.AttendanceSessionId=x.AttendanceSessionId JOIN people.StudentEnrollment e WITH (UPDLOCK,HOLDLOCK) ON e.EnrollmentId=x.EnrollmentId WHERE (s.SessionType=''''employee_shift'''' OR (s.ClassSectionId IS NOT NULL AND s.ClassSectionId<>e.ClassSectionId) OR s.SessionDate<e.StartDate OR s.SessionDate>COALESCE(e.EndDate,CONVERT(date,''''99991231''''))) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51506, ''''AttendanceEnrollment: operation violates the invariant.'''',1;
END;'');
 EXEC(N''CREATE OR ALTER TRIGGER attendance.TR_StudentAttendance_DomainIntegrity ON attendance.StudentAttendance AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Schools table(SchoolId uniqueidentifier PRIMARY KEY);
 INSERT @Schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
 IF EXISTS(SELECT 1 FROM attendance.StudentAttendance x WITH (UPDLOCK,HOLDLOCK) JOIN attendance.AttendanceSession s WITH (UPDLOCK,HOLDLOCK) ON s.AttendanceSessionId=x.AttendanceSessionId JOIN people.StudentEnrollment e WITH (UPDLOCK,HOLDLOCK) ON e.EnrollmentId=x.EnrollmentId WHERE (s.SessionType=''''employee_shift'''' OR (s.ClassSectionId IS NOT NULL AND s.ClassSectionId<>e.ClassSectionId) OR s.SessionDate<e.StartDate OR s.SessionDate>COALESCE(e.EndDate,CONVERT(date,''''99991231''''))) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51506, ''''AttendanceEnrollment: operation violates the invariant.'''',1;
END;'');
 EXEC(N''CREATE OR ALTER TRIGGER core.TR_SchoolYear_DomainIntegrity ON core.SchoolYear AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Schools table(SchoolId uniqueidentifier PRIMARY KEY);
 INSERT @Schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
 IF EXISTS(SELECT 1 FROM people.StudentEnrollment x WITH (UPDLOCK,HOLDLOCK) JOIN core.SchoolYear y WITH (UPDLOCK,HOLDLOCK) ON y.SchoolYearId=x.SchoolYearId WHERE (x.StartDate<y.StartDate OR x.StartDate>y.EndDate OR (x.EndDate IS NOT NULL AND x.EndDate>y.EndDate)) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51507, ''''EnrollmentDates: operation violates the invariant.'''',1;
END;'');
 EXEC(N''CREATE OR ALTER TRIGGER finance.TR_Charge_DomainIntegrity ON finance.Charge AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Schools table(SchoolId uniqueidentifier PRIMARY KEY);
 INSERT @Schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
 IF EXISTS(SELECT 1 FROM finance.PaymentAttempt x WITH (UPDLOCK,HOLDLOCK) JOIN finance.Installment i WITH (UPDLOCK,HOLDLOCK) ON i.InstallmentId=x.InstallmentId JOIN finance.Charge c WITH (UPDLOCK,HOLDLOCK) ON c.ChargeId=i.ChargeId WHERE (x.CurrencyCode<>c.CurrencyCode) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51508, ''''AttemptCurrency: operation violates the invariant.'''',1;
 IF EXISTS(SELECT 1 FROM finance.Charge x WITH (UPDLOCK,HOLDLOCK) OUTER APPLY(SELECT SUM(CASE WHEN a.AdjustmentType=''''debit_correction'''' THEN a.Amount ELSE -a.Amount END) total FROM finance.ChargeAdjustment a WITH (UPDLOCK,HOLDLOCK) WHERE a.SchoolId=x.SchoolId AND a.ChargeId=x.ChargeId) a OUTER APPLY(SELECT SUM(i.Amount) total FROM finance.Installment i WITH (UPDLOCK,HOLDLOCK) WHERE i.SchoolId=x.SchoolId AND i.ChargeId=x.ChargeId AND i.Status<>''''cancelled'''') i WHERE (x.Amount+COALESCE(a.total,0)<0 OR COALESCE(i.total,0)>x.Amount+COALESCE(a.total,0)) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51511, ''''InstallmentBudget: operation violates the invariant.'''',1;
END;'');
 EXEC(N''CREATE OR ALTER TRIGGER finance.TR_ChargeAdjustment_DomainIntegrity ON finance.ChargeAdjustment AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Schools table(SchoolId uniqueidentifier PRIMARY KEY);
 INSERT @Schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
 IF EXISTS(SELECT 1 FROM finance.Charge x WITH (UPDLOCK,HOLDLOCK) OUTER APPLY(SELECT SUM(CASE WHEN a.AdjustmentType=''''debit_correction'''' THEN a.Amount ELSE -a.Amount END) total FROM finance.ChargeAdjustment a WITH (UPDLOCK,HOLDLOCK) WHERE a.SchoolId=x.SchoolId AND a.ChargeId=x.ChargeId) a OUTER APPLY(SELECT SUM(i.Amount) total FROM finance.Installment i WITH (UPDLOCK,HOLDLOCK) WHERE i.SchoolId=x.SchoolId AND i.ChargeId=x.ChargeId AND i.Status<>''''cancelled'''') i WHERE (x.Amount+COALESCE(a.total,0)<0 OR COALESCE(i.total,0)>x.Amount+COALESCE(a.total,0)) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51511, ''''InstallmentBudget: operation violates the invariant.'''',1;
END;'');
 EXEC(N''CREATE OR ALTER TRIGGER finance.TR_Installment_DomainIntegrity ON finance.Installment AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Schools table(SchoolId uniqueidentifier PRIMARY KEY);
 INSERT @Schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
 IF EXISTS(SELECT 1 FROM finance.PaymentAttempt x WITH (UPDLOCK,HOLDLOCK) JOIN finance.Installment i WITH (UPDLOCK,HOLDLOCK) ON i.InstallmentId=x.InstallmentId JOIN finance.Charge c WITH (UPDLOCK,HOLDLOCK) ON c.ChargeId=i.ChargeId WHERE (x.CurrencyCode<>c.CurrencyCode) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51508, ''''AttemptCurrency: operation violates the invariant.'''',1;
 IF EXISTS(SELECT 1 FROM finance.Charge x WITH (UPDLOCK,HOLDLOCK) OUTER APPLY(SELECT SUM(CASE WHEN a.AdjustmentType=''''debit_correction'''' THEN a.Amount ELSE -a.Amount END) total FROM finance.ChargeAdjustment a WITH (UPDLOCK,HOLDLOCK) WHERE a.SchoolId=x.SchoolId AND a.ChargeId=x.ChargeId) a OUTER APPLY(SELECT SUM(i.Amount) total FROM finance.Installment i WITH (UPDLOCK,HOLDLOCK) WHERE i.SchoolId=x.SchoolId AND i.ChargeId=x.ChargeId AND i.Status<>''''cancelled'''') i WHERE (x.Amount+COALESCE(a.total,0)<0 OR COALESCE(i.total,0)>x.Amount+COALESCE(a.total,0)) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51511, ''''InstallmentBudget: operation violates the invariant.'''',1;
 IF EXISTS(SELECT 1 FROM finance.Installment x WITH (UPDLOCK,HOLDLOCK) OUTER APPLY(SELECT SUM(p.Amount-COALESCE(r.total,0)) total FROM finance.PaymentAttempt a WITH (UPDLOCK,HOLDLOCK) JOIN finance.Payment p WITH (UPDLOCK,HOLDLOCK) ON p.PaymentAttemptId=a.PaymentAttemptId OUTER APPLY(SELECT SUM(r.Amount) total FROM finance.PaymentReversal r WITH (UPDLOCK,HOLDLOCK) WHERE r.SchoolId=p.SchoolId AND r.PaymentId=p.PaymentId) r WHERE a.SchoolId=x.SchoolId AND a.InstallmentId=x.InstallmentId) p WHERE (COALESCE(p.total,0)>x.Amount OR (x.Status=''''cancelled'''' AND COALESCE(p.total,0)>0)) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51512, ''''InstallmentSettlement: operation violates the invariant.'''',1;
END;'');
 EXEC(N''CREATE OR ALTER TRIGGER finance.TR_Payment_DomainIntegrity ON finance.Payment AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Schools table(SchoolId uniqueidentifier PRIMARY KEY);
 INSERT @Schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
 IF EXISTS(SELECT 1 FROM finance.Payment x WITH (UPDLOCK,HOLDLOCK) JOIN finance.PaymentAttempt a WITH (UPDLOCK,HOLDLOCK) ON a.PaymentAttemptId=x.PaymentAttemptId WHERE (x.CurrencyCode<>a.CurrencyCode OR x.Amount<>a.Amount OR a.Status NOT IN (''''settled'''',''''refunded'''')) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51509, ''''PaymentSettlement: operation violates the invariant.'''',1;
 IF EXISTS(SELECT 1 FROM finance.Payment x WITH (UPDLOCK,HOLDLOCK) CROSS APPLY(SELECT SUM(r.Amount) total FROM finance.PaymentReversal r WITH (UPDLOCK,HOLDLOCK) WHERE r.SchoolId=x.SchoolId AND r.PaymentId=x.PaymentId) r WHERE (r.total>x.Amount) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51510, ''''ReversalTotal: operation violates the invariant.'''',1;
 IF EXISTS(SELECT 1 FROM finance.Installment x WITH (UPDLOCK,HOLDLOCK) OUTER APPLY(SELECT SUM(p.Amount-COALESCE(r.total,0)) total FROM finance.PaymentAttempt a WITH (UPDLOCK,HOLDLOCK) JOIN finance.Payment p WITH (UPDLOCK,HOLDLOCK) ON p.PaymentAttemptId=a.PaymentAttemptId OUTER APPLY(SELECT SUM(r.Amount) total FROM finance.PaymentReversal r WITH (UPDLOCK,HOLDLOCK) WHERE r.SchoolId=p.SchoolId AND r.PaymentId=p.PaymentId) r WHERE a.SchoolId=x.SchoolId AND a.InstallmentId=x.InstallmentId) p WHERE (COALESCE(p.total,0)>x.Amount OR (x.Status=''''cancelled'''' AND COALESCE(p.total,0)>0)) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51512, ''''InstallmentSettlement: operation violates the invariant.'''',1;
END;'');
 EXEC(N''CREATE OR ALTER TRIGGER finance.TR_PaymentAttempt_DomainIntegrity ON finance.PaymentAttempt AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Schools table(SchoolId uniqueidentifier PRIMARY KEY);
 INSERT @Schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
 IF EXISTS(SELECT 1 FROM finance.PaymentAttempt x WITH (UPDLOCK,HOLDLOCK) JOIN finance.Installment i WITH (UPDLOCK,HOLDLOCK) ON i.InstallmentId=x.InstallmentId JOIN finance.Charge c WITH (UPDLOCK,HOLDLOCK) ON c.ChargeId=i.ChargeId WHERE (x.CurrencyCode<>c.CurrencyCode) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51508, ''''AttemptCurrency: operation violates the invariant.'''',1;
 IF EXISTS(SELECT 1 FROM finance.Payment x WITH (UPDLOCK,HOLDLOCK) JOIN finance.PaymentAttempt a WITH (UPDLOCK,HOLDLOCK) ON a.PaymentAttemptId=x.PaymentAttemptId WHERE (x.CurrencyCode<>a.CurrencyCode OR x.Amount<>a.Amount OR a.Status NOT IN (''''settled'''',''''refunded'''')) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51509, ''''PaymentSettlement: operation violates the invariant.'''',1;
 IF EXISTS(SELECT 1 FROM finance.Installment x WITH (UPDLOCK,HOLDLOCK) OUTER APPLY(SELECT SUM(p.Amount-COALESCE(r.total,0)) total FROM finance.PaymentAttempt a WITH (UPDLOCK,HOLDLOCK) JOIN finance.Payment p WITH (UPDLOCK,HOLDLOCK) ON p.PaymentAttemptId=a.PaymentAttemptId OUTER APPLY(SELECT SUM(r.Amount) total FROM finance.PaymentReversal r WITH (UPDLOCK,HOLDLOCK) WHERE r.SchoolId=p.SchoolId AND r.PaymentId=p.PaymentId) r WHERE a.SchoolId=x.SchoolId AND a.InstallmentId=x.InstallmentId) p WHERE (COALESCE(p.total,0)>x.Amount OR (x.Status=''''cancelled'''' AND COALESCE(p.total,0)>0)) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51512, ''''InstallmentSettlement: operation violates the invariant.'''',1;
END;'');
 EXEC(N''CREATE OR ALTER TRIGGER finance.TR_PaymentReversal_DomainIntegrity ON finance.PaymentReversal AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Schools table(SchoolId uniqueidentifier PRIMARY KEY);
 INSERT @Schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
 IF EXISTS(SELECT 1 FROM finance.Payment x WITH (UPDLOCK,HOLDLOCK) CROSS APPLY(SELECT SUM(r.Amount) total FROM finance.PaymentReversal r WITH (UPDLOCK,HOLDLOCK) WHERE r.SchoolId=x.SchoolId AND r.PaymentId=x.PaymentId) r WHERE (r.total>x.Amount) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51510, ''''ReversalTotal: operation violates the invariant.'''',1;
 IF EXISTS(SELECT 1 FROM finance.Installment x WITH (UPDLOCK,HOLDLOCK) OUTER APPLY(SELECT SUM(p.Amount-COALESCE(r.total,0)) total FROM finance.PaymentAttempt a WITH (UPDLOCK,HOLDLOCK) JOIN finance.Payment p WITH (UPDLOCK,HOLDLOCK) ON p.PaymentAttemptId=a.PaymentAttemptId OUTER APPLY(SELECT SUM(r.Amount) total FROM finance.PaymentReversal r WITH (UPDLOCK,HOLDLOCK) WHERE r.SchoolId=p.SchoolId AND r.PaymentId=p.PaymentId) r WHERE a.SchoolId=x.SchoolId AND a.InstallmentId=x.InstallmentId) p WHERE (COALESCE(p.total,0)>x.Amount OR (x.Status=''''cancelled'''' AND COALESCE(p.total,0)>0)) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51512, ''''InstallmentSettlement: operation violates the invariant.'''',1;
END;'');
 EXEC(N''CREATE OR ALTER TRIGGER learning.TR_Assignment_DomainIntegrity ON learning.Assignment AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Schools table(SchoolId uniqueidentifier PRIMARY KEY);
 INSERT @Schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
 IF EXISTS(SELECT 1 FROM learning.Submission x WITH (UPDLOCK,HOLDLOCK) JOIN learning.Assignment w WITH (UPDLOCK,HOLDLOCK) ON w.AssignmentId=x.AssignmentId JOIN academic.TeachingAssignment a WITH (UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=w.TeachingAssignmentId JOIN people.StudentEnrollment e WITH (UPDLOCK,HOLDLOCK) ON e.EnrollmentId=x.EnrollmentId WHERE (a.ClassSectionId<>e.ClassSectionId OR a.SchoolYearId<>e.SchoolYearId) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51504, ''''SubmissionEnrollment: operation violates the invariant.'''',1;
 IF EXISTS(SELECT 1 FROM learning.SubmissionRevision x WITH (UPDLOCK,HOLDLOCK) JOIN learning.Submission s WITH (UPDLOCK,HOLDLOCK) ON s.SubmissionId=x.SubmissionId JOIN learning.Assignment a WITH (UPDLOCK,HOLDLOCK) ON a.AssignmentId=s.AssignmentId WHERE (x.Score>a.MaximumScore) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51505, ''''SubmissionScore: operation violates the invariant.'''',1;
END;'');
 EXEC(N''CREATE OR ALTER TRIGGER learning.TR_Submission_DomainIntegrity ON learning.Submission AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Schools table(SchoolId uniqueidentifier PRIMARY KEY);
 INSERT @Schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
 IF EXISTS(SELECT 1 FROM learning.Submission x WITH (UPDLOCK,HOLDLOCK) JOIN learning.Assignment w WITH (UPDLOCK,HOLDLOCK) ON w.AssignmentId=x.AssignmentId JOIN academic.TeachingAssignment a WITH (UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=w.TeachingAssignmentId JOIN people.StudentEnrollment e WITH (UPDLOCK,HOLDLOCK) ON e.EnrollmentId=x.EnrollmentId WHERE (a.ClassSectionId<>e.ClassSectionId OR a.SchoolYearId<>e.SchoolYearId) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51504, ''''SubmissionEnrollment: operation violates the invariant.'''',1;
 IF EXISTS(SELECT 1 FROM learning.SubmissionRevision x WITH (UPDLOCK,HOLDLOCK) JOIN learning.Submission s WITH (UPDLOCK,HOLDLOCK) ON s.SubmissionId=x.SubmissionId JOIN learning.Assignment a WITH (UPDLOCK,HOLDLOCK) ON a.AssignmentId=s.AssignmentId WHERE (x.Score>a.MaximumScore) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51505, ''''SubmissionScore: operation violates the invariant.'''',1;
END;'');
 EXEC(N''CREATE OR ALTER TRIGGER learning.TR_SubmissionRevision_DomainIntegrity ON learning.SubmissionRevision AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Schools table(SchoolId uniqueidentifier PRIMARY KEY);
 INSERT @Schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
 IF EXISTS(SELECT 1 FROM learning.SubmissionRevision x WITH (UPDLOCK,HOLDLOCK) JOIN learning.Submission s WITH (UPDLOCK,HOLDLOCK) ON s.SubmissionId=x.SubmissionId JOIN learning.Assignment a WITH (UPDLOCK,HOLDLOCK) ON a.AssignmentId=s.AssignmentId WHERE (x.Score>a.MaximumScore) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51505, ''''SubmissionScore: operation violates the invariant.'''',1;
END;'');
 EXEC(N''CREATE OR ALTER TRIGGER people.TR_StudentEnrollment_DomainIntegrity ON people.StudentEnrollment AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Schools table(SchoolId uniqueidentifier PRIMARY KEY);
 INSERT @Schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
 IF EXISTS(SELECT 1 FROM assessment.GradeItem x WITH (UPDLOCK,HOLDLOCK) JOIN assessment.Gradebook b WITH (UPDLOCK,HOLDLOCK) ON b.GradebookId=x.GradebookId JOIN academic.TeachingAssignment a WITH (UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=b.TeachingAssignmentId JOIN people.StudentEnrollment e WITH (UPDLOCK,HOLDLOCK) ON e.EnrollmentId=x.EnrollmentId WHERE (a.ClassSectionId<>e.ClassSectionId OR a.SchoolYearId<>e.SchoolYearId) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51502, ''''GradeEnrollment: operation violates the invariant.'''',1;
 IF EXISTS(SELECT 1 FROM learning.Submission x WITH (UPDLOCK,HOLDLOCK) JOIN learning.Assignment w WITH (UPDLOCK,HOLDLOCK) ON w.AssignmentId=x.AssignmentId JOIN academic.TeachingAssignment a WITH (UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=w.TeachingAssignmentId JOIN people.StudentEnrollment e WITH (UPDLOCK,HOLDLOCK) ON e.EnrollmentId=x.EnrollmentId WHERE (a.ClassSectionId<>e.ClassSectionId OR a.SchoolYearId<>e.SchoolYearId) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51504, ''''SubmissionEnrollment: operation violates the invariant.'''',1;
 IF EXISTS(SELECT 1 FROM attendance.StudentAttendance x WITH (UPDLOCK,HOLDLOCK) JOIN attendance.AttendanceSession s WITH (UPDLOCK,HOLDLOCK) ON s.AttendanceSessionId=x.AttendanceSessionId JOIN people.StudentEnrollment e WITH (UPDLOCK,HOLDLOCK) ON e.EnrollmentId=x.EnrollmentId WHERE (s.SessionType=''''employee_shift'''' OR (s.ClassSectionId IS NOT NULL AND s.ClassSectionId<>e.ClassSectionId) OR s.SessionDate<e.StartDate OR s.SessionDate>COALESCE(e.EndDate,CONVERT(date,''''99991231''''))) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51506, ''''AttendanceEnrollment: operation violates the invariant.'''',1;
 IF EXISTS(SELECT 1 FROM people.StudentEnrollment x WITH (UPDLOCK,HOLDLOCK) JOIN core.SchoolYear y WITH (UPDLOCK,HOLDLOCK) ON y.SchoolYearId=x.SchoolYearId WHERE (x.StartDate<y.StartDate OR x.StartDate>y.EndDate OR (x.EndDate IS NOT NULL AND x.EndDate>y.EndDate)) AND x.SchoolId IN (SELECT SchoolId FROM @Schools)) THROW 51507, ''''EnrollmentDates: operation violates the invariant.'''',1;
END;'');
 EXEC(N''CREATE OR ALTER TRIGGER assessment.TR_PublishedGrade_Immutable ON assessment.PublishedGrade AFTER UPDATE,DELETE AS BEGIN SET NOCOUNT ON; IF EXISTS(SELECT 1 FROM deleted) THROW 51520,''''Historical rows are immutable; append a correction through the documented workflow.'''',1; END;'');
 EXEC(N''CREATE OR ALTER TRIGGER finance.TR_PaymentReversal_Immutable ON finance.PaymentReversal AFTER UPDATE,DELETE AS BEGIN SET NOCOUNT ON; IF EXISTS(SELECT 1 FROM deleted) THROW 51520,''''Historical rows are immutable; append a correction through the documented workflow.'''',1; END;'');
 EXEC(N''CREATE OR ALTER TRIGGER assessment.TR_GradebookWorkflowEvent_Immutable ON assessment.GradebookWorkflowEvent AFTER UPDATE,DELETE AS BEGIN SET NOCOUNT ON; IF EXISTS(SELECT 1 FROM deleted) THROW 51520,''''Historical rows are immutable; append a correction through the documented workflow.'''',1; END;'');
 EXEC(N''CREATE OR ALTER TRIGGER audit.TR_AuditEvent_Immutable ON audit.AuditEvent AFTER UPDATE,DELETE AS BEGIN SET NOCOUNT ON; IF EXISTS(SELECT 1 FROM deleted) THROW 51520,''''Historical rows are immutable; append a correction through the documented workflow.'''',1; END;'');
 EXEC(N''CREATE OR ALTER TRIGGER assessment.TR_GradeItem_WriteState ON assessment.GradeItem AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM assessment.Gradebook b WITH(UPDLOCK,HOLDLOCK) JOIN (SELECT SchoolId,GradebookId FROM inserted UNION SELECT SchoolId,GradebookId FROM deleted) a ON a.SchoolId=b.SchoolId AND a.GradebookId=b.GradebookId WHERE b.Status NOT IN (''''draft'''',''''returned'''')) THROW 51521,''''Grade items are writable only in draft or returned gradebooks.'''',1;
END;'');
 
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW;
END CATCH;
';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(8,N''008_domain_integrity.sql'',0x96c01de7ede16197e7cb12aaf921699216ec0b152a974beda0978cd7ce7fcb21,''executed'');';
 -- BEGIN 009_grade_workflow.sql
 EXEC sys.sp_executesql N'SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
';
 EXEC sys.sp_executesql N'

IF COL_LENGTH(''assessment.GradePublication'',''SealedAtUtc'') IS NULL
 ALTER TABLE assessment.GradePublication ADD SealedAtUtc datetime2(3) NULL;
IF DATABASE_PRINCIPAL_ID(N''awn_backend'') IS NULL CREATE ROLE awn_backend AUTHORIZATION dbo;
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name=''UX_Certificate_Token'') CREATE UNIQUE INDEX UX_Certificate_Token ON assessment.Certificate(VerificationTokenHash);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name=''UX_Receipt_Token'') CREATE UNIQUE INDEX UX_Receipt_Token ON finance.Receipt(VerificationTokenHash);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name=''UX_ReopenRequest_Pending'') CREATE UNIQUE INDEX UX_ReopenRequest_Pending ON assessment.ReopenRequest(SchoolId,GradebookId) WHERE Status=''submitted'';

';
 EXEC sys.sp_executesql N'
CREATE OR ALTER FUNCTION security.HasSchoolPermission(@UserId uniqueidentifier,@SchoolId uniqueidentifier,@PermissionCode varchar(120))
RETURNS bit AS
BEGIN
 DECLARE @now datetime2(3)=SYSUTCDATETIME(),@allowed bit=0;
 IF NOT EXISTS(SELECT 1 FROM security.UserAccount WHERE UserId=@UserId AND Status=''active'' AND (LockedUntilUtc IS NULL OR LockedUntilUtc<=@now)) RETURN 0;
 IF EXISTS(SELECT 1 FROM security.UserRole ur JOIN core.School s ON s.SchoolId=@SchoolId JOIN security.Permission p ON p.Code=@PermissionCode LEFT JOIN security.RolePermission rp ON rp.RoleId=ur.RoleId AND rp.PermissionId=p.PermissionId LEFT JOIN security.RolePermissionScope ps ON ps.UserRoleId=ur.UserRoleId AND ps.PermissionId=p.PermissionId AND ps.ValidFrom<=@now AND (ps.ValidTo IS NULL OR ps.ValidTo>@now) WHERE ur.UserId=@UserId AND ur.Status=''active'' AND ur.ValidFrom<=@now AND (ur.ValidTo IS NULL OR ur.ValidTo>@now) AND ((ur.SchoolId=@SchoolId) OR (ur.SchoolId IS NULL AND ur.OrganizationId=s.OrganizationId)) AND (rp.PermissionId IS NOT NULL OR ps.Effect=''allow'')) SET @allowed=1;
 IF EXISTS(SELECT 1 FROM security.UserRole ur JOIN core.School s ON s.SchoolId=@SchoolId JOIN security.RolePermissionScope ps ON ps.UserRoleId=ur.UserRoleId JOIN security.Permission p ON p.PermissionId=ps.PermissionId AND p.Code=@PermissionCode WHERE ur.UserId=@UserId AND ur.Status=''active'' AND ur.ValidFrom<=@now AND (ur.ValidTo IS NULL OR ur.ValidTo>@now) AND (ur.SchoolId=@SchoolId OR (ur.SchoolId IS NULL AND ur.OrganizationId=s.OrganizationId)) AND ps.Effect=''deny'' AND ps.ValidFrom<=@now AND (ps.ValidTo IS NULL OR ps.ValidTo>@now)) RETURN 0;
 RETURN @allowed;
END;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER TRIGGER assessment.TR_Publication_Seal ON assessment.GradePublication AFTER UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM deleted d LEFT JOIN inserted i ON i.GradePublicationId=d.GradePublicationId WHERE i.GradePublicationId IS NULL OR i.SchoolId<>d.SchoolId OR i.GradebookId<>d.GradebookId OR i.VersionNo<>d.VersionNo OR i.PublishedByUserId<>d.PublishedByUserId OR i.PublishedAtUtc<>d.PublishedAtUtc OR (d.SealedAtUtc IS NOT NULL AND (i.SealedAtUtc IS NULL OR i.SealedAtUtc<>d.SealedAtUtc OR i.SnapshotHash<>d.SnapshotHash))) THROW 51600,''Publication identity and sealed content cannot be changed.'',1;
END;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER TRIGGER assessment.TR_PublishedGrade_Seal ON assessment.PublishedGrade AFTER INSERT AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted i JOIN assessment.GradePublication p WITH(UPDLOCK,HOLDLOCK) ON p.GradePublicationId=i.GradePublicationId WHERE p.SealedAtUtc IS NOT NULL) THROW 51601,''Cannot append to a sealed publication.'',1;
END;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER PROCEDURE assessment.TransitionGradebook
 @SchoolId uniqueidentifier,@GradebookId uniqueidentifier,@ActorUserId uniqueidentifier,@ExpectedRevision int,@ToStatus varchar(20),@Note nvarchar(2000)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @from varchar(20),@revision int,@permission varchar(120);
 BEGIN TRY
  BEGIN TRANSACTION;
  SELECT @from=Status,@revision=Revision FROM assessment.Gradebook WITH(UPDLOCK,HOLDLOCK) WHERE SchoolId=@SchoolId AND GradebookId=@GradebookId;
  IF @from IS NULL OR @revision<>@ExpectedRevision THROW 51602,''Gradebook not found or stale revision.'',1;
  SET @permission=CASE WHEN @ToStatus=''submitted'' THEN ''grades.enter'' WHEN @ToStatus IN (''reviewed'',''returned'') THEN ''grades.review'' WHEN @ToStatus=''approved'' THEN ''grades.publish'' END;
  IF @permission IS NULL OR security.HasSchoolPermission(@ActorUserId,@SchoolId,@permission)=0 THROW 51603,''Permission denied.'',1;
  IF NOT ((@from IN (''draft'',''returned'') AND @ToStatus=''submitted'') OR (@from=''submitted'' AND @ToStatus IN (''reviewed'',''returned'')) OR (@from=''reviewed'' AND @ToStatus IN (''approved'',''returned''))) THROW 51604,''Invalid gradebook transition.'',1;
  IF NOT EXISTS(SELECT 1 FROM assessment.Gradebook b JOIN assessment.GradingPolicy p ON p.GradingPolicyId=b.GradingPolicyId WHERE b.GradebookId=@GradebookId AND p.Status=''approved'') THROW 51605,''An approved policy is required.'',1;
  UPDATE assessment.Gradebook SET Status=@ToStatus,Revision=Revision+1 WHERE GradebookId=@GradebookId;
  INSERT assessment.GradebookWorkflowEvent(SchoolId,GradebookId,ActorUserId,FromStatus,ToStatus,Note,Revision) VALUES(@SchoolId,@GradebookId,@ActorUserId,@from,@ToStatus,@Note,@revision+1);
  COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER PROCEDURE assessment.PublishGradebook
 @SchoolId uniqueidentifier,@GradebookId uniqueidentifier,@ActorUserId uniqueidentifier,@ExpectedRevision int
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @status varchar(20),@revision int,@policy uniqueidentifier,@class uniqueidentifier,@mode varchar(20),@round varchar(20),@version int,@pub uniqueidentifier=NEWID(),@payload nvarchar(max);
 BEGIN TRY
  BEGIN TRANSACTION;
  SELECT @status=b.Status,@revision=b.Revision,@policy=b.GradingPolicyId,@class=a.ClassSectionId,@mode=p.AssessmentMode,@round=p.RoundingRule FROM assessment.Gradebook b WITH(UPDLOCK,HOLDLOCK) JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=b.TeachingAssignmentId JOIN assessment.GradingPolicy p WITH(UPDLOCK,HOLDLOCK) ON p.GradingPolicyId=b.GradingPolicyId WHERE b.SchoolId=@SchoolId AND b.GradebookId=@GradebookId AND p.Status=''approved'';
  IF @status IS NULL OR @status<>''approved'' OR @revision<>@ExpectedRevision THROW 51606,''Approved gradebook with current revision required.'',1;
  IF security.HasSchoolPermission(@ActorUserId,@SchoolId,''grades.publish'')=0 THROW 51603,''Permission denied.'',1;
  -- Numeric totals are calculated by SQL; missing required results cannot silently become zero.
  IF NOT EXISTS(SELECT 1 FROM assessment.GradingComponent WHERE GradingPolicyId=@policy) THROW 51607,''Policy has no components.'',1;
  IF EXISTS(SELECT 1 FROM people.StudentEnrollment e WITH(UPDLOCK,HOLDLOCK) CROSS JOIN assessment.GradingComponent c WITH(UPDLOCK,HOLDLOCK) LEFT JOIN assessment.GradeItem g WITH(UPDLOCK,HOLDLOCK) ON g.EnrollmentId=e.EnrollmentId AND g.GradingComponentId=c.GradingComponentId AND g.GradebookId=@GradebookId WHERE e.SchoolId=@SchoolId AND e.ClassSectionId=@class AND e.Status=''active'' AND c.GradingPolicyId=@policy AND c.IsRequired=1 AND (g.GradeItemId IS NULL OR (@mode IN (''weighted'',''hybrid'') AND c.MaximumScore IS NOT NULL AND g.Score IS NULL) OR (@mode=''descriptive'' AND g.DescriptiveLevel IS NULL))) THROW 51608,''Required student results are missing.'',1;
  IF @mode IN (''weighted'',''hybrid'') AND EXISTS(SELECT 1 FROM assessment.GradingComponent WHERE GradingPolicyId=@policy GROUP BY GradingPolicyId HAVING SUM(CASE WHEN MaximumScore IS NOT NULL THEN COALESCE(WeightPercent,0) ELSE 0 END)<>100 OR SUM(CASE WHEN MaximumScore IS NOT NULL AND WeightPercent IS NULL THEN 1 ELSE 0 END)>0) THROW 51613,''Numeric components must have weights totaling 100.'',1;
  DECLARE @results table(EnrollmentId uniqueidentifier PRIMARY KEY,Score decimal(9,4),MaximumScore decimal(9,4),DescriptiveResult nvarchar(500),DetailsJson nvarchar(max));
  INSERT @results
  SELECT e.EnrollmentId,CASE WHEN @mode=''descriptive'' THEN NULL ELSE SUM(COALESCE(g.Score/NULLIF(c.MaximumScore,0)*c.WeightPercent,0)) END,CASE WHEN @mode=''descriptive'' THEN NULL ELSE 100 END,
   CASE WHEN @mode IN (''descriptive'',''hybrid'') THEN N''See component results'' ELSE NULL END,
   (SELECT c2.Code,c2.Name,c2.MaximumScore,c2.WeightPercent,g2.Score,g2.DescriptiveLevel,g2.Feedback FROM assessment.GradingComponent c2 LEFT JOIN assessment.GradeItem g2 ON g2.GradingComponentId=c2.GradingComponentId AND g2.EnrollmentId=e.EnrollmentId AND g2.GradebookId=@GradebookId WHERE c2.GradingPolicyId=@policy ORDER BY c2.SortOrder,c2.Code FOR JSON PATH)
  FROM people.StudentEnrollment e WITH(UPDLOCK,HOLDLOCK) CROSS JOIN assessment.GradingComponent c WITH(UPDLOCK,HOLDLOCK) LEFT JOIN assessment.GradeItem g WITH(UPDLOCK,HOLDLOCK) ON g.EnrollmentId=e.EnrollmentId AND g.GradingComponentId=c.GradingComponentId AND g.GradebookId=@GradebookId
  WHERE e.SchoolId=@SchoolId AND e.ClassSectionId=@class AND e.Status=''active'' AND c.GradingPolicyId=@policy GROUP BY e.EnrollmentId;
  IF NOT EXISTS(SELECT 1 FROM @results) THROW 51609,''No active student results to publish.'',1;
  UPDATE @results SET Score=CASE @round WHEN ''nearest'' THEN ROUND(Score,0) WHEN ''floor'' THEN FLOOR(Score) WHEN ''ceiling'' THEN CEILING(Score) ELSE Score END;
  SELECT @payload=(SELECT EnrollmentId,Score,MaximumScore,DescriptiveResult,DetailsJson FROM @results ORDER BY EnrollmentId FOR JSON PATH,INCLUDE_NULL_VALUES);
  SELECT @version=COALESCE(MAX(VersionNo),0)+1 FROM assessment.GradePublication WITH(UPDLOCK,HOLDLOCK) WHERE SchoolId=@SchoolId AND GradebookId=@GradebookId;
  INSERT assessment.GradePublication(GradePublicationId,SchoolId,GradebookId,VersionNo,SnapshotHash,PublishedByUserId) VALUES(@pub,@SchoolId,@GradebookId,@version,HASHBYTES(''SHA2_256'',@payload),@ActorUserId);
  INSERT assessment.PublishedGrade(SchoolId,GradePublicationId,EnrollmentId,Score,MaximumScore,DescriptiveResult,DetailsJson) SELECT @SchoolId,@pub,EnrollmentId,Score,MaximumScore,DescriptiveResult,DetailsJson FROM @results;
  UPDATE assessment.GradePublication SET SealedAtUtc=SYSUTCDATETIME() WHERE GradePublicationId=@pub;
  UPDATE assessment.Gradebook SET Status=''locked'',LockedAtUtc=SYSUTCDATETIME(),Revision=Revision+1 WHERE GradebookId=@GradebookId;
  INSERT assessment.GradebookWorkflowEvent(SchoolId,GradebookId,ActorUserId,FromStatus,ToStatus,Revision) VALUES(@SchoolId,@GradebookId,@ActorUserId,''approved'',''locked'',@revision+1);
  COMMIT;
  SELECT @pub AS GradePublicationId,@version AS VersionNo;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER PROCEDURE assessment.RequestGradebookReopen @SchoolId uniqueidentifier,@GradebookId uniqueidentifier,@ActorUserId uniqueidentifier,@Reason nvarchar(2000)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF NULLIF(LTRIM(RTRIM(@Reason)),N'''') IS NULL THROW 51610,''A reason is required.'',1;
  IF security.HasSchoolPermission(@ActorUserId,@SchoolId,''grades.enter'')=0 AND security.HasSchoolPermission(@ActorUserId,@SchoolId,''grades.reopen'')=0 THROW 51603,''Permission denied.'',1;
  IF NOT EXISTS(SELECT 1 FROM assessment.Gradebook WITH(UPDLOCK,HOLDLOCK) WHERE SchoolId=@SchoolId AND GradebookId=@GradebookId AND Status=''locked'') THROW 51611,''Only a locked gradebook may be reopened.'',1;
  INSERT assessment.ReopenRequest(SchoolId,GradebookId,RequestedByUserId,Reason) VALUES(@SchoolId,@GradebookId,@ActorUserId,@Reason);
  COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER PROCEDURE assessment.DecideGradebookReopen @SchoolId uniqueidentifier,@ReopenRequestId uniqueidentifier,@ActorUserId uniqueidentifier,@Approve bit,@Note nvarchar(2000)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @book uniqueidentifier,@requester uniqueidentifier,@revision int;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF @Approve IS NULL OR NULLIF(LTRIM(RTRIM(@Note)),N'''') IS NULL THROW 51610,''Decision and note required.'',1;
  IF security.HasSchoolPermission(@ActorUserId,@SchoolId,''grades.reopen'')=0 THROW 51603,''Permission denied.'',1;
  SELECT @book=GradebookId,@requester=RequestedByUserId FROM assessment.ReopenRequest WITH(UPDLOCK,HOLDLOCK) WHERE SchoolId=@SchoolId AND ReopenRequestId=@ReopenRequestId AND Status=''submitted'';
  IF @book IS NULL OR @requester=@ActorUserId THROW 51612,''Pending request and independent approver required.'',1;
  SELECT @revision=Revision FROM assessment.Gradebook WITH(UPDLOCK,HOLDLOCK) WHERE GradebookId=@book AND Status=''locked'';
  IF @revision IS NULL THROW 51611,''Gradebook must remain locked.'',1;
  UPDATE assessment.ReopenRequest SET Status=CASE WHEN @Approve=1 THEN ''approved'' ELSE ''rejected'' END,DecidedByUserId=@ActorUserId,DecidedAtUtc=SYSUTCDATETIME(),DecisionNote=LEFT(@Note,2000) WHERE ReopenRequestId=@ReopenRequestId;
  IF @Approve=1 BEGIN
   UPDATE assessment.Gradebook SET Status=''returned'',LockedAtUtc=NULL,Revision=Revision+1 WHERE GradebookId=@book;
   INSERT assessment.GradebookWorkflowEvent(SchoolId,GradebookId,ActorUserId,FromStatus,ToStatus,Note,Revision) VALUES(@SchoolId,@book,@ActorUserId,''locked'',''returned'',@Note,@revision+1);
  END;
  COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
';
 EXEC sys.sp_executesql N'
-- Identity binding, student/teacher assignment authorization and tenant-filtered reads are backend contracts.
DENY INSERT,UPDATE,DELETE ON assessment.GradePublication TO awn_backend;
DENY INSERT,UPDATE,DELETE ON assessment.PublishedGrade TO awn_backend;
DENY INSERT,UPDATE,DELETE ON assessment.GradebookWorkflowEvent TO awn_backend;
DENY INSERT,UPDATE,DELETE ON assessment.ReopenRequest TO awn_backend;
DENY INSERT,UPDATE,DELETE ON assessment.Gradebook TO awn_backend;
DENY UPDATE,DELETE ON audit.AuditEvent TO awn_backend;
GRANT EXECUTE ON assessment.TransitionGradebook TO awn_backend;
GRANT EXECUTE ON assessment.PublishGradebook TO awn_backend;
GRANT EXECUTE ON assessment.RequestGradebookReopen TO awn_backend;
GRANT EXECUTE ON assessment.DecideGradebookReopen TO awn_backend;
';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(9,N''009_grade_workflow.sql'',0x78b6bee752b1b2a710fefd058be447921df0ade12976ee3087a4bc7d2c6f817e,''executed'');';
 -- BEGIN 010_finance_commands.sql
 EXEC sys.sp_executesql N'SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER PROCEDURE finance.SettlePaymentAttempt @SchoolId uniqueidentifier,@PaymentAttemptId uniqueidentifier,@ActorUserId uniqueidentifier,@ProviderReference nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @amount decimal(19,4),@currency char(3),@status varchar(20),@payment uniqueidentifier,@installment uniqueidentifier;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF security.HasSchoolPermission(@ActorUserId,@SchoolId,''finance.manage'')=0 THROW 51700,''Finance permission required.'',1;
  SELECT @installment=InstallmentId FROM finance.PaymentAttempt WHERE SchoolId=@SchoolId AND PaymentAttemptId=@PaymentAttemptId;
  IF @installment IS NULL THROW 51701,''Payment attempt not found.'',1;
  -- Serialize all settlements for one installment before changing any payment rows.
  SELECT @amount=Amount FROM finance.Installment WITH(UPDLOCK,HOLDLOCK) WHERE SchoolId=@SchoolId AND InstallmentId=@installment AND Status<>''cancelled'';
  IF @amount IS NULL THROW 51702,''Active installment required.'',1;
  SELECT @amount=Amount,@currency=CurrencyCode,@status=Status FROM finance.PaymentAttempt WITH(UPDLOCK,HOLDLOCK) WHERE SchoolId=@SchoolId AND PaymentAttemptId=@PaymentAttemptId;
  SELECT @payment=PaymentId FROM finance.Payment WITH(UPDLOCK,HOLDLOCK) WHERE SchoolId=@SchoolId AND PaymentAttemptId=@PaymentAttemptId;
  IF @payment IS NOT NULL BEGIN
   IF NOT EXISTS(SELECT 1 FROM finance.Payment WHERE PaymentId=@payment AND ProviderReference=@ProviderReference) THROW 51703,''Idempotency conflict: provider reference differs.'',1;
   COMMIT; SELECT @payment AS PaymentId; RETURN;
  END;
  IF NULLIF(LTRIM(RTRIM(@ProviderReference)),N'''') IS NULL OR @status NOT IN (''created'',''pending'',''authorized'',''settled'') THROW 51704,''Invalid settlement state or provider reference.'',1;
  UPDATE finance.PaymentAttempt SET Status=''settled'',CompletedAtUtc=SYSUTCDATETIME(),ProviderReference=@ProviderReference WHERE PaymentAttemptId=@PaymentAttemptId;
  SET @payment=NEWID();
  INSERT finance.Payment(PaymentId,SchoolId,PaymentAttemptId,Amount,CurrencyCode,ProviderReference,SettledAtUtc) VALUES(@payment,@SchoolId,@PaymentAttemptId,@amount,@currency,@ProviderReference,SYSUTCDATETIME());
  INSERT audit.AuditEvent(OrganizationId,SchoolId,ActorUserId,ActionCode,EntityType,EntityId,Outcome) SELECT OrganizationId,@SchoolId,@ActorUserId,''payment.settled'',''finance.Payment'',CONVERT(nvarchar(36),@payment),''success'' FROM core.School WHERE SchoolId=@SchoolId;
  COMMIT; SELECT @payment AS PaymentId;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER PROCEDURE finance.ReversePayment @SchoolId uniqueidentifier,@PaymentId uniqueidentifier,@ActorUserId uniqueidentifier,@Amount decimal(19,4),@Reason nvarchar(1000),@ExternalReference nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @original decimal(19,4),@reversed decimal(19,4),@id uniqueidentifier,@installment uniqueidentifier;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF security.HasSchoolPermission(@ActorUserId,@SchoolId,''finance.manage'')=0 THROW 51700,''Finance permission required.'',1;
  IF @Amount IS NULL OR @Amount<=0 OR NULLIF(LTRIM(RTRIM(@Reason)),N'''') IS NULL OR NULLIF(LTRIM(RTRIM(@ExternalReference)),N'''') IS NULL THROW 51705,''Positive amount, reason and idempotency reference required.'',1;
  SELECT @installment=a.InstallmentId FROM finance.Payment p JOIN finance.PaymentAttempt a ON a.PaymentAttemptId=p.PaymentAttemptId WHERE p.SchoolId=@SchoolId AND p.PaymentId=@PaymentId;
  SELECT @original=Amount FROM finance.Installment WITH(UPDLOCK,HOLDLOCK) WHERE SchoolId=@SchoolId AND InstallmentId=@installment;
  SET @original=NULL;
  SELECT @original=Amount FROM finance.Payment WITH(UPDLOCK,HOLDLOCK) WHERE SchoolId=@SchoolId AND PaymentId=@PaymentId;
  IF @original IS NULL THROW 51706,''Payment not found.'',1;
  SELECT @id=PaymentReversalId FROM finance.PaymentReversal WITH(UPDLOCK,HOLDLOCK) WHERE SchoolId=@SchoolId AND PaymentId=@PaymentId AND ExternalReference=@ExternalReference;
  IF @id IS NOT NULL BEGIN
   IF NOT EXISTS(SELECT 1 FROM finance.PaymentReversal WHERE PaymentReversalId=@id AND Amount=@Amount AND Reason=@Reason) THROW 51703,''Idempotency conflict: reversal payload differs.'',1;
   COMMIT; SELECT @id AS PaymentReversalId; RETURN;
  END;
  SELECT @reversed=COALESCE(SUM(Amount),0) FROM finance.PaymentReversal WITH(UPDLOCK,HOLDLOCK) WHERE SchoolId=@SchoolId AND PaymentId=@PaymentId;
  IF @reversed+@Amount>@original THROW 51707,''Refund exceeds the remaining settled amount.'',1;
  SET @id=NEWID();
  INSERT finance.PaymentReversal(PaymentReversalId,SchoolId,PaymentId,Amount,Reason,ExternalReference,ApprovedByUserId) VALUES(@id,@SchoolId,@PaymentId,@Amount,@Reason,@ExternalReference,@ActorUserId);
  UPDATE finance.Payment SET Status=CASE WHEN @reversed+@Amount=@original THEN ''refunded'' ELSE ''partially_refunded'' END WHERE PaymentId=@PaymentId;
  INSERT audit.AuditEvent(OrganizationId,SchoolId,ActorUserId,ActionCode,EntityType,EntityId,Outcome) SELECT OrganizationId,@SchoolId,@ActorUserId,''payment.reversed'',''finance.PaymentReversal'',CONVERT(nvarchar(36),@id),''success'' FROM core.School WHERE SchoolId=@SchoolId;
  COMMIT; SELECT @id AS PaymentReversalId;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
';
 EXEC sys.sp_executesql N'
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name=''UX_PaymentReversal_Reference'') CREATE UNIQUE INDEX UX_PaymentReversal_Reference ON finance.PaymentReversal(SchoolId,PaymentId,ExternalReference) WHERE ExternalReference IS NOT NULL;
DENY INSERT,UPDATE,DELETE ON finance.Payment TO awn_backend;
DENY INSERT,UPDATE,DELETE ON finance.PaymentReversal TO awn_backend;
GRANT EXECUTE ON finance.SettlePaymentAttempt TO awn_backend;
GRANT EXECUTE ON finance.ReversePayment TO awn_backend;
';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(10,N''010_finance_commands.sql'',0xa1c07d9ea28aeaeac3dfddcdfc9ba82b295b926a0ce21fa7b3bc7c689cd4bb6e,''executed'');';
 -- BEGIN 011_learning_and_appointments.sql
 EXEC sys.sp_executesql N'SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;

CREATE TABLE learning.Rubric(
 RubricId uniqueidentifier NOT NULL CONSTRAINT DF_Rubric_Id DEFAULT NEWSEQUENTIALID(),
 SchoolId uniqueidentifier NOT NULL,
 Code nvarchar(50) NOT NULL,
 VersionNo int NOT NULL,
 Title nvarchar(200) NOT NULL,
 Status varchar(20) NOT NULL DEFAULT ''draft'',
 CONSTRAINT PK_Rubric PRIMARY KEY(RubricId),
 CONSTRAINT UQ_Rubric_Scope UNIQUE(SchoolId,RubricId),
 CONSTRAINT FK_Rubric_School FOREIGN KEY(SchoolId) REFERENCES core.School(SchoolId),
 UNIQUE(SchoolId,Code,VersionNo),
 CHECK(VersionNo>0 AND Status IN (''draft'',''approved'',''retired''))
);
CREATE TABLE learning.RubricCriterion(
 RubricCriterionId uniqueidentifier NOT NULL CONSTRAINT DF_RubricCriterion_Id DEFAULT NEWSEQUENTIALID(),
 SchoolId uniqueidentifier NOT NULL,
 RubricId uniqueidentifier NOT NULL,
 Code nvarchar(50) NOT NULL,
 Description nvarchar(1000) NOT NULL,
 MaximumScore decimal(9,4) NOT NULL,
 SortOrder smallint NOT NULL,
 CONSTRAINT PK_RubricCriterion PRIMARY KEY(RubricCriterionId),
 CONSTRAINT UQ_RubricCriterion_Scope UNIQUE(SchoolId,RubricCriterionId),
 CONSTRAINT FK_RubricCriterion_School FOREIGN KEY(SchoolId) REFERENCES core.School(SchoolId),
 CONSTRAINT FK_RubricCriterion_Rubric FOREIGN KEY(SchoolId,RubricId) REFERENCES learning.Rubric(SchoolId,RubricId),
 UNIQUE(SchoolId,RubricId,Code),
 UNIQUE(SchoolId,RubricId,RubricCriterionId),
 CHECK(MaximumScore>0 AND SortOrder>=0)
);
CREATE TABLE learning.SupervisoryVisit(
 SupervisoryVisitId uniqueidentifier NOT NULL CONSTRAINT DF_SupervisoryVisit_Id DEFAULT NEWSEQUENTIALID(),
 SchoolId uniqueidentifier NOT NULL,
 RubricId uniqueidentifier NOT NULL,
 EmployeeId uniqueidentifier NOT NULL,
 SupervisorUserId uniqueidentifier NOT NULL,
 ScheduledAtUtc datetime2(3) NOT NULL,
 CompletedAtUtc datetime2(3) NULL,
 Status varchar(20) NOT NULL DEFAULT ''scheduled'',
 Recommendations nvarchar(3000) NULL,
 CONSTRAINT PK_SupervisoryVisit PRIMARY KEY(SupervisoryVisitId),
 CONSTRAINT UQ_SupervisoryVisit_Scope UNIQUE(SchoolId,SupervisoryVisitId),
 CONSTRAINT FK_SupervisoryVisit_School FOREIGN KEY(SchoolId) REFERENCES core.School(SchoolId),
 CONSTRAINT FK_SupervisoryVisit_Rubric FOREIGN KEY(SchoolId,RubricId) REFERENCES learning.Rubric(SchoolId,RubricId),
 CONSTRAINT FK_SupervisoryVisit_Employee FOREIGN KEY(SchoolId,EmployeeId) REFERENCES people.EmployeeProfile(SchoolId,EmployeeId),
 CONSTRAINT FK_SupervisoryVisit_Supervisor FOREIGN KEY(SupervisorUserId) REFERENCES security.UserAccount(UserId),
 UNIQUE(SchoolId,SupervisoryVisitId,RubricId),
 CHECK(Status IN (''scheduled'',''in_progress'',''completed'',''cancelled'')),
 CHECK((Status=''completed'' AND CompletedAtUtc IS NOT NULL) OR (Status<>''completed'' AND CompletedAtUtc IS NULL))
);
CREATE TABLE learning.VisitRating(
 VisitRatingId uniqueidentifier NOT NULL CONSTRAINT DF_VisitRating_Id DEFAULT NEWSEQUENTIALID(),
 SchoolId uniqueidentifier NOT NULL,
 SupervisoryVisitId uniqueidentifier NOT NULL,
 RubricId uniqueidentifier NOT NULL,
 RubricCriterionId uniqueidentifier NOT NULL,
 Score decimal(9,4) NOT NULL,
 Comment nvarchar(2000) NULL,
 CONSTRAINT PK_VisitRating PRIMARY KEY(VisitRatingId),
 CONSTRAINT UQ_VisitRating_Scope UNIQUE(SchoolId,VisitRatingId),
 CONSTRAINT FK_VisitRating_School FOREIGN KEY(SchoolId) REFERENCES core.School(SchoolId),
 CONSTRAINT FK_VisitRating_Visit FOREIGN KEY(SchoolId,SupervisoryVisitId,RubricId) REFERENCES learning.SupervisoryVisit(SchoolId,SupervisoryVisitId,RubricId),
 CONSTRAINT FK_VisitRating_Criterion FOREIGN KEY(SchoolId,RubricId,RubricCriterionId) REFERENCES learning.RubricCriterion(SchoolId,RubricId,RubricCriterionId),
 UNIQUE(SchoolId,SupervisoryVisitId,RubricCriterionId),
 CHECK(Score>=0)
);
CREATE TABLE assessment.Question(
 QuestionId uniqueidentifier NOT NULL CONSTRAINT DF_Question_Id DEFAULT NEWSEQUENTIALID(),
 SchoolId uniqueidentifier NOT NULL,
 SubjectId uniqueidentifier NOT NULL,
 Code nvarchar(80) NOT NULL,
 VersionNo int NOT NULL,
 Prompt nvarchar(max) NOT NULL,
 QuestionType varchar(20) NOT NULL,
 BloomLevel tinyint NOT NULL,
 AnswerKeyJson nvarchar(max) NOT NULL,
 CreatedByUserId uniqueidentifier NOT NULL,
 CONSTRAINT PK_Question PRIMARY KEY(QuestionId),
 CONSTRAINT UQ_Question_Scope UNIQUE(SchoolId,QuestionId),
 CONSTRAINT FK_Question_School FOREIGN KEY(SchoolId) REFERENCES core.School(SchoolId),
 CONSTRAINT FK_Question_Subject FOREIGN KEY(SchoolId,SubjectId) REFERENCES academic.Subject(SchoolId,SubjectId),
 CONSTRAINT FK_Question_Author FOREIGN KEY(CreatedByUserId) REFERENCES security.UserAccount(UserId),
 UNIQUE(SchoolId,Code,VersionNo),
 CHECK(VersionNo>0 AND BloomLevel BETWEEN 1 AND 6 AND QuestionType IN (''single_choice'',''multiple_choice'',''text'',''numeric'')),
 CHECK(ISJSON(AnswerKeyJson)=1)
);
CREATE TABLE assessment.QuestionOption(
 QuestionOptionId uniqueidentifier NOT NULL CONSTRAINT DF_QuestionOption_Id DEFAULT NEWSEQUENTIALID(),
 SchoolId uniqueidentifier NOT NULL,
 QuestionId uniqueidentifier NOT NULL,
 Code nvarchar(30) NOT NULL,
 OptionText nvarchar(2000) NOT NULL,
 SortOrder smallint NOT NULL,
 CONSTRAINT PK_QuestionOption PRIMARY KEY(QuestionOptionId),
 CONSTRAINT UQ_QuestionOption_Scope UNIQUE(SchoolId,QuestionOptionId),
 CONSTRAINT FK_QuestionOption_School FOREIGN KEY(SchoolId) REFERENCES core.School(SchoolId),
 CONSTRAINT FK_QuestionOption_Question FOREIGN KEY(SchoolId,QuestionId) REFERENCES assessment.Question(SchoolId,QuestionId),
 UNIQUE(SchoolId,QuestionId,Code),
 CHECK(SortOrder>=0)
);
CREATE TABLE assessment.Exam(
 ExamId uniqueidentifier NOT NULL CONSTRAINT DF_Exam_Id DEFAULT NEWSEQUENTIALID(),
 SchoolId uniqueidentifier NOT NULL,
 TeachingAssignmentId uniqueidentifier NOT NULL,
 Title nvarchar(200) NOT NULL,
 OpensAtUtc datetime2(3) NOT NULL,
 ClosesAtUtc datetime2(3) NOT NULL,
 DurationMinutes smallint NOT NULL,
 MaximumAttempts smallint NOT NULL,
 Status varchar(20) NOT NULL DEFAULT ''draft'',
 CONSTRAINT PK_Exam PRIMARY KEY(ExamId),
 CONSTRAINT UQ_Exam_Scope UNIQUE(SchoolId,ExamId),
 CONSTRAINT FK_Exam_School FOREIGN KEY(SchoolId) REFERENCES core.School(SchoolId),
 CONSTRAINT FK_Exam_Teaching FOREIGN KEY(SchoolId,TeachingAssignmentId) REFERENCES academic.TeachingAssignment(SchoolId,TeachingAssignmentId),
 CHECK(OpensAtUtc<ClosesAtUtc AND DurationMinutes>0 AND MaximumAttempts>0),
 CHECK(Status IN (''draft'',''published'',''closed'',''archived''))
);
CREATE TABLE assessment.ExamQuestion(
 ExamQuestionId uniqueidentifier NOT NULL CONSTRAINT DF_ExamQuestion_Id DEFAULT NEWSEQUENTIALID(),
 SchoolId uniqueidentifier NOT NULL,
 ExamId uniqueidentifier NOT NULL,
 QuestionId uniqueidentifier NOT NULL,
 MaximumScore decimal(9,4) NOT NULL,
 SortOrder smallint NOT NULL,
 CONSTRAINT PK_ExamQuestion PRIMARY KEY(ExamQuestionId),
 CONSTRAINT UQ_ExamQuestion_Scope UNIQUE(SchoolId,ExamQuestionId),
 CONSTRAINT FK_ExamQuestion_School FOREIGN KEY(SchoolId) REFERENCES core.School(SchoolId),
 CONSTRAINT FK_ExamQuestion_Exam FOREIGN KEY(SchoolId,ExamId) REFERENCES assessment.Exam(SchoolId,ExamId),
 CONSTRAINT FK_ExamQuestion_Question FOREIGN KEY(SchoolId,QuestionId) REFERENCES assessment.Question(SchoolId,QuestionId),
 UNIQUE(SchoolId,ExamId,QuestionId),
 UNIQUE(SchoolId,ExamId,ExamQuestionId),
 CHECK(MaximumScore>0 AND SortOrder>=0)
);
CREATE TABLE assessment.ExamAttempt(
 ExamAttemptId uniqueidentifier NOT NULL CONSTRAINT DF_ExamAttempt_Id DEFAULT NEWSEQUENTIALID(),
 SchoolId uniqueidentifier NOT NULL,
 ExamId uniqueidentifier NOT NULL,
 EnrollmentId uniqueidentifier NOT NULL,
 AttemptNo smallint NOT NULL,
 StartedAtUtc datetime2(3) NOT NULL,
 SubmittedAtUtc datetime2(3) NULL,
 Status varchar(20) NOT NULL DEFAULT ''in_progress'',
 CONSTRAINT PK_ExamAttempt PRIMARY KEY(ExamAttemptId),
 CONSTRAINT UQ_ExamAttempt_Scope UNIQUE(SchoolId,ExamAttemptId),
 CONSTRAINT FK_ExamAttempt_School FOREIGN KEY(SchoolId) REFERENCES core.School(SchoolId),
 CONSTRAINT FK_ExamAttempt_Exam FOREIGN KEY(SchoolId,ExamId) REFERENCES assessment.Exam(SchoolId,ExamId),
 CONSTRAINT FK_ExamAttempt_Enrollment FOREIGN KEY(SchoolId,EnrollmentId) REFERENCES people.StudentEnrollment(SchoolId,EnrollmentId),
 UNIQUE(SchoolId,ExamId,EnrollmentId,AttemptNo),
 UNIQUE(SchoolId,ExamAttemptId,ExamId),
 CHECK(AttemptNo>0 AND Status IN (''in_progress'',''submitted'',''graded'',''void'')),
 CHECK(SubmittedAtUtc IS NULL OR SubmittedAtUtc>=StartedAtUtc)
);
CREATE TABLE assessment.ExamResponse(
 ExamResponseId uniqueidentifier NOT NULL CONSTRAINT DF_ExamResponse_Id DEFAULT NEWSEQUENTIALID(),
 SchoolId uniqueidentifier NOT NULL,
 ExamAttemptId uniqueidentifier NOT NULL,
 ExamId uniqueidentifier NOT NULL,
 ExamQuestionId uniqueidentifier NOT NULL,
 AnswerJson nvarchar(max) NOT NULL,
 Score decimal(9,4) NULL,
 Feedback nvarchar(2000) NULL,
 CONSTRAINT PK_ExamResponse PRIMARY KEY(ExamResponseId),
 CONSTRAINT UQ_ExamResponse_Scope UNIQUE(SchoolId,ExamResponseId),
 CONSTRAINT FK_ExamResponse_School FOREIGN KEY(SchoolId) REFERENCES core.School(SchoolId),
 CONSTRAINT FK_ExamResponse_Attempt FOREIGN KEY(SchoolId,ExamAttemptId,ExamId) REFERENCES assessment.ExamAttempt(SchoolId,ExamAttemptId,ExamId),
 CONSTRAINT FK_ExamResponse_Question FOREIGN KEY(SchoolId,ExamId,ExamQuestionId) REFERENCES assessment.ExamQuestion(SchoolId,ExamId,ExamQuestionId),
 UNIQUE(SchoolId,ExamAttemptId,ExamQuestionId),
 CHECK(ISJSON(AnswerJson)=1 AND (Score IS NULL OR Score>=0))
);
CREATE TABLE operations.OfficeHourSlot(
 OfficeHourSlotId uniqueidentifier NOT NULL CONSTRAINT DF_OfficeHourSlot_Id DEFAULT NEWSEQUENTIALID(),
 SchoolId uniqueidentifier NOT NULL,
 EmployeeId uniqueidentifier NOT NULL,
 StartsAtUtc datetime2(3) NOT NULL,
 EndsAtUtc datetime2(3) NOT NULL,
 Status varchar(20) NOT NULL DEFAULT ''open'',
 CONSTRAINT PK_OfficeHourSlot PRIMARY KEY(OfficeHourSlotId),
 CONSTRAINT UQ_OfficeHourSlot_Scope UNIQUE(SchoolId,OfficeHourSlotId),
 CONSTRAINT FK_OfficeHourSlot_School FOREIGN KEY(SchoolId) REFERENCES core.School(SchoolId),
 CONSTRAINT FK_OfficeHourSlot_Employee FOREIGN KEY(SchoolId,EmployeeId) REFERENCES people.EmployeeProfile(SchoolId,EmployeeId),
 CHECK(StartsAtUtc<EndsAtUtc AND Status IN (''open'',''closed'',''cancelled''))
);
CREATE TABLE operations.Appointment(
 AppointmentId uniqueidentifier NOT NULL CONSTRAINT DF_Appointment_Id DEFAULT NEWSEQUENTIALID(),
 SchoolId uniqueidentifier NOT NULL,
 OfficeHourSlotId uniqueidentifier NOT NULL,
 GuardianId uniqueidentifier NOT NULL,
 StudentId uniqueidentifier NOT NULL,
 Reason nvarchar(1000) NOT NULL,
 Status varchar(20) NOT NULL DEFAULT ''booked'',
 CreatedAtUtc datetime2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
 CONSTRAINT PK_Appointment PRIMARY KEY(AppointmentId),
 CONSTRAINT UQ_Appointment_Scope UNIQUE(SchoolId,AppointmentId),
 CONSTRAINT FK_Appointment_School FOREIGN KEY(SchoolId) REFERENCES core.School(SchoolId),
 CONSTRAINT FK_Appointment_Slot FOREIGN KEY(SchoolId,OfficeHourSlotId) REFERENCES operations.OfficeHourSlot(SchoolId,OfficeHourSlotId),
 CONSTRAINT FK_Appointment_Student FOREIGN KEY(SchoolId,StudentId) REFERENCES people.StudentProfile(SchoolId,StudentId),
 CONSTRAINT FK_Appointment_Guardian FOREIGN KEY(GuardianId) REFERENCES people.GuardianProfile(GuardianId),
 CHECK(Status IN (''booked'',''completed'',''cancelled'',''no_show''))
);
CREATE UNIQUE INDEX UX_Appointment_Slot ON operations.Appointment(SchoolId,OfficeHourSlotId) WHERE Status<>''cancelled'';
CREATE TABLE learning.Conversation(
 ConversationId uniqueidentifier NOT NULL CONSTRAINT DF_Conversation_Id DEFAULT NEWSEQUENTIALID(),
 SchoolId uniqueidentifier NOT NULL,
 Subject nvarchar(200) NOT NULL,
 CreatedByUserId uniqueidentifier NOT NULL,
 CreatedAtUtc datetime2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
 CONSTRAINT PK_Conversation PRIMARY KEY(ConversationId),
 CONSTRAINT UQ_Conversation_Scope UNIQUE(SchoolId,ConversationId),
 CONSTRAINT FK_Conversation_School FOREIGN KEY(SchoolId) REFERENCES core.School(SchoolId),
 CONSTRAINT FK_Conversation_Author FOREIGN KEY(CreatedByUserId) REFERENCES security.UserAccount(UserId)
);
CREATE TABLE learning.ConversationMember(
 ConversationMemberId uniqueidentifier NOT NULL CONSTRAINT DF_ConversationMember_Id DEFAULT NEWSEQUENTIALID(),
 SchoolId uniqueidentifier NOT NULL,
 ConversationId uniqueidentifier NOT NULL,
 UserId uniqueidentifier NOT NULL,
 JoinedAtUtc datetime2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
 LeftAtUtc datetime2(3) NULL,
 CONSTRAINT PK_ConversationMember PRIMARY KEY(ConversationMemberId),
 CONSTRAINT UQ_ConversationMember_Scope UNIQUE(SchoolId,ConversationMemberId),
 CONSTRAINT FK_ConversationMember_School FOREIGN KEY(SchoolId) REFERENCES core.School(SchoolId),
 CONSTRAINT FK_ConversationMember_Conversation FOREIGN KEY(SchoolId,ConversationId) REFERENCES learning.Conversation(SchoolId,ConversationId),
 CONSTRAINT FK_ConversationMember_User FOREIGN KEY(UserId) REFERENCES security.UserAccount(UserId),
 UNIQUE(SchoolId,ConversationId,UserId),
 CHECK(LeftAtUtc IS NULL OR LeftAtUtc>=JoinedAtUtc)
);
CREATE TABLE learning.Message(
 MessageId uniqueidentifier NOT NULL CONSTRAINT DF_Message_Id DEFAULT NEWSEQUENTIALID(),
 SchoolId uniqueidentifier NOT NULL,
 ConversationId uniqueidentifier NOT NULL,
 SenderUserId uniqueidentifier NOT NULL,
 Body nvarchar(max) NOT NULL,
 SentAtUtc datetime2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
 AttachmentFileObjectId uniqueidentifier NULL,
 CONSTRAINT PK_Message PRIMARY KEY(MessageId),
 CONSTRAINT UQ_Message_Scope UNIQUE(SchoolId,MessageId),
 CONSTRAINT FK_Message_School FOREIGN KEY(SchoolId) REFERENCES core.School(SchoolId),
 CONSTRAINT FK_Message_Member FOREIGN KEY(SchoolId,ConversationId,SenderUserId) REFERENCES learning.ConversationMember(SchoolId,ConversationId,UserId),
 CONSTRAINT FK_Message_File FOREIGN KEY(SchoolId,AttachmentFileObjectId) REFERENCES core.FileObject(SchoolId,FileObjectId)
);
CREATE TABLE learning.Notification(
 NotificationId uniqueidentifier NOT NULL CONSTRAINT DF_Notification_Id DEFAULT NEWSEQUENTIALID(),
 SchoolId uniqueidentifier NOT NULL,
 RecipientUserId uniqueidentifier NOT NULL,
 Title nvarchar(200) NOT NULL,
 Body nvarchar(2000) NOT NULL,
 CreatedAtUtc datetime2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
 ReadAtUtc datetime2(3) NULL,
 CONSTRAINT PK_Notification PRIMARY KEY(NotificationId),
 CONSTRAINT UQ_Notification_Scope UNIQUE(SchoolId,NotificationId),
 CONSTRAINT FK_Notification_School FOREIGN KEY(SchoolId) REFERENCES core.School(SchoolId),
 CONSTRAINT FK_Notification_Recipient FOREIGN KEY(RecipientUserId) REFERENCES security.UserAccount(UserId),
 CHECK(ReadAtUtc IS NULL OR ReadAtUtc>=CreatedAtUtc)
);

';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(11,N''011_learning_and_appointments.sql'',0x68adca7122b6f72e60a5a4a956bac89fe1363572cf31d0a69ef8d594d4395f6f,''executed'');';
 -- BEGIN 012_learning_integrity.sql
 EXEC sys.sp_executesql N'SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;

EXEC(N''CREATE OR ALTER TRIGGER learning.TR_VisitRating_CoverageIntegrity ON learning.VisitRating AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM learning.VisitRating x WITH(UPDLOCK,HOLDLOCK) JOIN learning.RubricCriterion c WITH(UPDLOCK,HOLDLOCK) ON c.RubricCriterionId=x.RubricCriterionId WHERE (x.Score>c.MaximumScore) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52000,''''VisitScore invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER learning.TR_RubricCriterion_CoverageIntegrity ON learning.RubricCriterion AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM learning.VisitRating x WITH(UPDLOCK,HOLDLOCK) JOIN learning.RubricCriterion c WITH(UPDLOCK,HOLDLOCK) ON c.RubricCriterionId=x.RubricCriterionId WHERE (x.Score>c.MaximumScore) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52000,''''VisitScore invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER assessment.TR_ExamResponse_CoverageIntegrity ON assessment.ExamResponse AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM assessment.ExamResponse x WITH(UPDLOCK,HOLDLOCK) JOIN assessment.ExamQuestion q WITH(UPDLOCK,HOLDLOCK) ON q.ExamQuestionId=x.ExamQuestionId WHERE (x.Score>q.MaximumScore) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52001,''''ExamScore invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER assessment.TR_ExamQuestion_CoverageIntegrity ON assessment.ExamQuestion AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM assessment.ExamResponse x WITH(UPDLOCK,HOLDLOCK) JOIN assessment.ExamQuestion q WITH(UPDLOCK,HOLDLOCK) ON q.ExamQuestionId=x.ExamQuestionId WHERE (x.Score>q.MaximumScore) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52001,''''ExamScore invariant violated.'''',1;
IF EXISTS(SELECT 1 FROM assessment.ExamQuestion x WITH(UPDLOCK,HOLDLOCK) JOIN assessment.Exam e WITH(UPDLOCK,HOLDLOCK) ON e.ExamId=x.ExamId JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=e.TeachingAssignmentId JOIN assessment.Question q WITH(UPDLOCK,HOLDLOCK) ON q.QuestionId=x.QuestionId WHERE (a.SubjectId<>q.SubjectId) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52005,''''ExamSubject invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER assessment.TR_ExamAttempt_CoverageIntegrity ON assessment.ExamAttempt AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM assessment.ExamAttempt x WITH(UPDLOCK,HOLDLOCK) JOIN assessment.Exam e WITH(UPDLOCK,HOLDLOCK) ON e.ExamId=x.ExamId JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=e.TeachingAssignmentId JOIN people.StudentEnrollment n WITH(UPDLOCK,HOLDLOCK) ON n.EnrollmentId=x.EnrollmentId WHERE (n.ClassSectionId<>a.ClassSectionId OR n.SchoolYearId<>a.SchoolYearId OR x.AttemptNo>e.MaximumAttempts OR x.StartedAtUtc<e.OpensAtUtc OR x.StartedAtUtc>=e.ClosesAtUtc) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52002,''''ExamEnrollment invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER assessment.TR_Exam_CoverageIntegrity ON assessment.Exam AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM assessment.ExamAttempt x WITH(UPDLOCK,HOLDLOCK) JOIN assessment.Exam e WITH(UPDLOCK,HOLDLOCK) ON e.ExamId=x.ExamId JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=e.TeachingAssignmentId JOIN people.StudentEnrollment n WITH(UPDLOCK,HOLDLOCK) ON n.EnrollmentId=x.EnrollmentId WHERE (n.ClassSectionId<>a.ClassSectionId OR n.SchoolYearId<>a.SchoolYearId OR x.AttemptNo>e.MaximumAttempts OR x.StartedAtUtc<e.OpensAtUtc OR x.StartedAtUtc>=e.ClosesAtUtc) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52002,''''ExamEnrollment invariant violated.'''',1;
IF EXISTS(SELECT 1 FROM assessment.ExamQuestion x WITH(UPDLOCK,HOLDLOCK) JOIN assessment.Exam e WITH(UPDLOCK,HOLDLOCK) ON e.ExamId=x.ExamId JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=e.TeachingAssignmentId JOIN assessment.Question q WITH(UPDLOCK,HOLDLOCK) ON q.QuestionId=x.QuestionId WHERE (a.SubjectId<>q.SubjectId) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52005,''''ExamSubject invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER academic.TR_TeachingAssignment_CoverageIntegrity ON academic.TeachingAssignment AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM assessment.ExamAttempt x WITH(UPDLOCK,HOLDLOCK) JOIN assessment.Exam e WITH(UPDLOCK,HOLDLOCK) ON e.ExamId=x.ExamId JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=e.TeachingAssignmentId JOIN people.StudentEnrollment n WITH(UPDLOCK,HOLDLOCK) ON n.EnrollmentId=x.EnrollmentId WHERE (n.ClassSectionId<>a.ClassSectionId OR n.SchoolYearId<>a.SchoolYearId OR x.AttemptNo>e.MaximumAttempts OR x.StartedAtUtc<e.OpensAtUtc OR x.StartedAtUtc>=e.ClosesAtUtc) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52002,''''ExamEnrollment invariant violated.'''',1;
IF EXISTS(SELECT 1 FROM assessment.ExamQuestion x WITH(UPDLOCK,HOLDLOCK) JOIN assessment.Exam e WITH(UPDLOCK,HOLDLOCK) ON e.ExamId=x.ExamId JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=e.TeachingAssignmentId JOIN assessment.Question q WITH(UPDLOCK,HOLDLOCK) ON q.QuestionId=x.QuestionId WHERE (a.SubjectId<>q.SubjectId) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52005,''''ExamSubject invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER people.TR_StudentEnrollment_CoverageIntegrity ON people.StudentEnrollment AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM assessment.ExamAttempt x WITH(UPDLOCK,HOLDLOCK) JOIN assessment.Exam e WITH(UPDLOCK,HOLDLOCK) ON e.ExamId=x.ExamId JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=e.TeachingAssignmentId JOIN people.StudentEnrollment n WITH(UPDLOCK,HOLDLOCK) ON n.EnrollmentId=x.EnrollmentId WHERE (n.ClassSectionId<>a.ClassSectionId OR n.SchoolYearId<>a.SchoolYearId OR x.AttemptNo>e.MaximumAttempts OR x.StartedAtUtc<e.OpensAtUtc OR x.StartedAtUtc>=e.ClosesAtUtc) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52002,''''ExamEnrollment invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER operations.TR_OfficeHourSlot_CoverageIntegrity ON operations.OfficeHourSlot AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM operations.OfficeHourSlot x WITH(UPDLOCK,HOLDLOCK) JOIN operations.OfficeHourSlot y WITH(UPDLOCK,HOLDLOCK) ON y.SchoolId=x.SchoolId AND y.EmployeeId=x.EmployeeId AND y.OfficeHourSlotId<>x.OfficeHourSlotId WHERE (x.Status<>''''cancelled'''' AND y.Status<>''''cancelled'''' AND x.StartsAtUtc<y.EndsAtUtc AND y.StartsAtUtc<x.EndsAtUtc) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52003,''''SlotOverlap invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER operations.TR_Appointment_CoverageIntegrity ON operations.Appointment AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM operations.Appointment x WITH(UPDLOCK,HOLDLOCK) WHERE (x.Status<>''''cancelled'''' AND NOT EXISTS(SELECT 1 FROM people.StudentGuardian g WITH(UPDLOCK,HOLDLOCK) WHERE g.SchoolId=x.SchoolId AND g.StudentId=x.StudentId AND g.GuardianId=x.GuardianId AND g.Status=''''active'''')) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52004,''''AppointmentGuardian invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER people.TR_StudentGuardian_CoverageIntegrity ON people.StudentGuardian AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM operations.Appointment x WITH(UPDLOCK,HOLDLOCK) WHERE (x.Status<>''''cancelled'''' AND NOT EXISTS(SELECT 1 FROM people.StudentGuardian g WITH(UPDLOCK,HOLDLOCK) WHERE g.SchoolId=x.SchoolId AND g.StudentId=x.StudentId AND g.GuardianId=x.GuardianId AND g.Status=''''active'''')) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52004,''''AppointmentGuardian invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER assessment.TR_Question_CoverageIntegrity ON assessment.Question AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM assessment.ExamQuestion x WITH(UPDLOCK,HOLDLOCK) JOIN assessment.Exam e WITH(UPDLOCK,HOLDLOCK) ON e.ExamId=x.ExamId JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=e.TeachingAssignmentId JOIN assessment.Question q WITH(UPDLOCK,HOLDLOCK) ON q.QuestionId=x.QuestionId WHERE (a.SubjectId<>q.SubjectId) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52005,''''ExamSubject invariant violated.'''',1;
END;'');

';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(12,N''012_learning_integrity.sql'',0x99785df692ce4ff170cc1e9d5b6b4ebe7750587d8f8413adc3b03f6c8bf55b64,''executed'');';
 -- BEGIN 013_stable_constraint_names.sql
 EXEC sys.sp_executesql N'SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @schema sysname,@table sysname,@old sysname,@new sysname,@kind varchar(2),@definition nvarchar(max),@qualified nvarchar(776);
DECLARE names CURSOR LOCAL FAST_FORWARD FOR
SELECT s.name,t.name,o.name,o.type,COALESCE(c.definition,COL_NAME(d.parent_object_id,d.parent_column_id),k.cols)
FROM sys.objects o JOIN sys.tables t ON t.object_id=o.parent_object_id JOIN sys.schemas s ON s.schema_id=t.schema_id
LEFT JOIN sys.check_constraints c ON c.object_id=o.object_id
LEFT JOIN sys.default_constraints d ON d.object_id=o.object_id
OUTER APPLY(SELECT STRING_AGG(CONVERT(nvarchar(max),COL_NAME(ic.object_id,ic.column_id)),N''_'') WITHIN GROUP(ORDER BY ic.key_ordinal) cols FROM sys.index_columns ic JOIN sys.key_constraints kc ON kc.parent_object_id=ic.object_id AND kc.unique_index_id=ic.index_id WHERE kc.object_id=o.object_id AND ic.key_ordinal>0) k
WHERE c.is_system_named=1 OR d.is_system_named=1 OR EXISTS(SELECT 1 FROM sys.key_constraints kc WHERE kc.object_id=o.object_id AND kc.is_system_named=1);
OPEN names; FETCH NEXT FROM names INTO @schema,@table,@old,@kind,@definition;
WHILE @@FETCH_STATUS=0 BEGIN
 SET @new=CONVERT(sysname,LEFT(@kind+''_''+@table,95)+''_''+LEFT(CONVERT(varchar(64),HASHBYTES(''SHA2_256'',@definition),2),16));
 SET @qualified=QUOTENAME(@schema)+N''.''+QUOTENAME(@old);
 EXEC sys.sp_rename @objname=@qualified,@newname=@new,@objtype=N''OBJECT'';
 FETCH NEXT FROM names INTO @schema,@table,@old,@kind,@definition;
END;
CLOSE names; DEALLOCATE names;

';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(13,N''013_stable_constraint_names.sql'',0x406a3dbd6e8b42157e3a3b7231fbdbf8a5dea4d90557c11b690a6a4cd913fd58,''executed'');';
 -- BEGIN 014_operational_coverage.sql
 EXEC sys.sp_executesql N'SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;

CREATE TABLE operations.BehaviorCategory(
 BehaviorCategoryId uniqueidentifier NOT NULL CONSTRAINT DF_BehaviorCategory_Id DEFAULT NEWSEQUENTIALID(),
 SchoolId uniqueidentifier NOT NULL,
 Code nvarchar(50) NOT NULL,
 Name nvarchar(160) NOT NULL,
 DefaultPoints smallint NOT NULL,
 CONSTRAINT PK_BehaviorCategory PRIMARY KEY(BehaviorCategoryId),
 CONSTRAINT UQ_BehaviorCategory_Scope UNIQUE(SchoolId,BehaviorCategoryId),
 CONSTRAINT FK_BehaviorCategory_School FOREIGN KEY(SchoolId) REFERENCES core.School(SchoolId),
 UNIQUE(SchoolId,Code)
);
CREATE TABLE operations.BehaviorEntry(
 BehaviorEntryId uniqueidentifier NOT NULL CONSTRAINT DF_BehaviorEntry_Id DEFAULT NEWSEQUENTIALID(),
 SchoolId uniqueidentifier NOT NULL,
 StudentId uniqueidentifier NOT NULL,
 BehaviorCategoryId uniqueidentifier NOT NULL,
 Points smallint NOT NULL,
 Note nvarchar(2000) NOT NULL,
 RecordedByUserId uniqueidentifier NOT NULL,
 OccurredAtUtc datetime2(3) NOT NULL,
 ReversesBehaviorEntryId uniqueidentifier NULL,
 CONSTRAINT PK_BehaviorEntry PRIMARY KEY(BehaviorEntryId),
 CONSTRAINT UQ_BehaviorEntry_Scope UNIQUE(SchoolId,BehaviorEntryId),
 CONSTRAINT FK_BehaviorEntry_School FOREIGN KEY(SchoolId) REFERENCES core.School(SchoolId),
 CONSTRAINT FK_BehaviorEntry_Student FOREIGN KEY(SchoolId,StudentId) REFERENCES people.StudentProfile(SchoolId,StudentId),
 CONSTRAINT FK_BehaviorEntry_Category FOREIGN KEY(SchoolId,BehaviorCategoryId) REFERENCES operations.BehaviorCategory(SchoolId,BehaviorCategoryId),
 CONSTRAINT FK_BehaviorEntry_Author FOREIGN KEY(RecordedByUserId) REFERENCES security.UserAccount(UserId),
 CHECK(Points<>0)
);
ALTER TABLE operations.BehaviorEntry ADD CONSTRAINT FK_BehaviorEntry_Reversal FOREIGN KEY(SchoolId,ReversesBehaviorEntryId) REFERENCES operations.BehaviorEntry(SchoolId,BehaviorEntryId);
CREATE UNIQUE INDEX UX_BehaviorEntry_Reversal ON operations.BehaviorEntry(SchoolId,ReversesBehaviorEntryId) WHERE ReversesBehaviorEntryId IS NOT NULL;
CREATE TABLE attendance.LeaveEntitlement(
 LeaveEntitlementId uniqueidentifier NOT NULL CONSTRAINT DF_LeaveEntitlement_Id DEFAULT NEWSEQUENTIALID(),
 SchoolId uniqueidentifier NOT NULL,
 EmployeeId uniqueidentifier NOT NULL,
 LeaveTypeCode varchar(40) NOT NULL,
 PeriodStart date NOT NULL,
 PeriodEnd date NOT NULL,
 EntitledDays decimal(7,2) NOT NULL,
 CONSTRAINT PK_LeaveEntitlement PRIMARY KEY(LeaveEntitlementId),
 CONSTRAINT UQ_LeaveEntitlement_Scope UNIQUE(SchoolId,LeaveEntitlementId),
 CONSTRAINT FK_LeaveEntitlement_School FOREIGN KEY(SchoolId) REFERENCES core.School(SchoolId),
 CONSTRAINT FK_LeaveEntitlement_Employee FOREIGN KEY(SchoolId,EmployeeId) REFERENCES people.EmployeeProfile(SchoolId,EmployeeId),
 UNIQUE(SchoolId,EmployeeId,LeaveTypeCode,PeriodStart),
 CHECK(PeriodStart<=PeriodEnd AND EntitledDays>=0)
);
CREATE TABLE attendance.LeaveUsage(
 LeaveUsageId uniqueidentifier NOT NULL CONSTRAINT DF_LeaveUsage_Id DEFAULT NEWSEQUENTIALID(),
 SchoolId uniqueidentifier NOT NULL,
 LeaveEntitlementId uniqueidentifier NOT NULL,
 LeaveRequestId uniqueidentifier NOT NULL,
 DaysUsed decimal(7,2) NOT NULL,
 CONSTRAINT PK_LeaveUsage PRIMARY KEY(LeaveUsageId),
 CONSTRAINT UQ_LeaveUsage_Scope UNIQUE(SchoolId,LeaveUsageId),
 CONSTRAINT FK_LeaveUsage_School FOREIGN KEY(SchoolId) REFERENCES core.School(SchoolId),
 CONSTRAINT FK_LeaveUsage_Entitlement FOREIGN KEY(SchoolId,LeaveEntitlementId) REFERENCES attendance.LeaveEntitlement(SchoolId,LeaveEntitlementId),
 CONSTRAINT FK_LeaveUsage_Request FOREIGN KEY(SchoolId,LeaveRequestId) REFERENCES attendance.LeaveRequest(SchoolId,LeaveRequestId),
 UNIQUE(SchoolId,LeaveRequestId),
 CHECK(DaysUsed>0)
);
CREATE TABLE transport.RunChaperone(
 RunChaperoneId uniqueidentifier NOT NULL CONSTRAINT DF_RunChaperone_Id DEFAULT NEWSEQUENTIALID(),
 SchoolId uniqueidentifier NOT NULL,
 RouteRunId uniqueidentifier NOT NULL,
 EmployeeId uniqueidentifier NOT NULL,
 CONSTRAINT PK_RunChaperone PRIMARY KEY(RunChaperoneId),
 CONSTRAINT UQ_RunChaperone_Scope UNIQUE(SchoolId,RunChaperoneId),
 CONSTRAINT FK_RunChaperone_School FOREIGN KEY(SchoolId) REFERENCES core.School(SchoolId),
 CONSTRAINT FK_RunChaperone_Run FOREIGN KEY(SchoolId,RouteRunId) REFERENCES transport.RouteRun(SchoolId,RouteRunId),
 CONSTRAINT FK_RunChaperone_Employee FOREIGN KEY(SchoolId,EmployeeId) REFERENCES people.EmployeeProfile(SchoolId,EmployeeId),
 UNIQUE(SchoolId,RouteRunId,EmployeeId)
);
CREATE TABLE transport.StudentRide(
 StudentRideId uniqueidentifier NOT NULL CONSTRAINT DF_StudentRide_Id DEFAULT NEWSEQUENTIALID(),
 SchoolId uniqueidentifier NOT NULL,
 RouteRunId uniqueidentifier NOT NULL,
 TransportEnrollmentId uniqueidentifier NOT NULL,
 BoardedAtUtc datetime2(3) NULL,
 AlightedAtUtc datetime2(3) NULL,
 RecordedByUserId uniqueidentifier NOT NULL,
 CONSTRAINT PK_StudentRide PRIMARY KEY(StudentRideId),
 CONSTRAINT UQ_StudentRide_Scope UNIQUE(SchoolId,StudentRideId),
 CONSTRAINT FK_StudentRide_School FOREIGN KEY(SchoolId) REFERENCES core.School(SchoolId),
 CONSTRAINT FK_StudentRide_Run FOREIGN KEY(SchoolId,RouteRunId) REFERENCES transport.RouteRun(SchoolId,RouteRunId),
 CONSTRAINT FK_StudentRide_Enrollment FOREIGN KEY(SchoolId,TransportEnrollmentId) REFERENCES transport.TransportEnrollment(SchoolId,TransportEnrollmentId),
 CONSTRAINT FK_StudentRide_Recorder FOREIGN KEY(RecordedByUserId) REFERENCES security.UserAccount(UserId),
 UNIQUE(SchoolId,RouteRunId,TransportEnrollmentId),
 CHECK(AlightedAtUtc IS NULL OR (BoardedAtUtc IS NOT NULL AND AlightedAtUtc>=BoardedAtUtc))
);
CREATE TABLE transport.VehicleMaintenance(
 VehicleMaintenanceId uniqueidentifier NOT NULL CONSTRAINT DF_VehicleMaintenance_Id DEFAULT NEWSEQUENTIALID(),
 SchoolId uniqueidentifier NOT NULL,
 VehicleId uniqueidentifier NOT NULL,
 ServiceDate date NOT NULL,
 Description nvarchar(2000) NOT NULL,
 Cost decimal(19,4) NOT NULL,
 CurrencyCode char(3) NOT NULL,
 OdometerKm int NULL,
 CONSTRAINT PK_VehicleMaintenance PRIMARY KEY(VehicleMaintenanceId),
 CONSTRAINT UQ_VehicleMaintenance_Scope UNIQUE(SchoolId,VehicleMaintenanceId),
 CONSTRAINT FK_VehicleMaintenance_School FOREIGN KEY(SchoolId) REFERENCES core.School(SchoolId),
 CONSTRAINT FK_VehicleMaintenance_Vehicle FOREIGN KEY(SchoolId,VehicleId) REFERENCES transport.Vehicle(SchoolId,VehicleId),
 CHECK(Cost>=0 AND (OdometerKm IS NULL OR OdometerKm>=0) AND CurrencyCode LIKE ''[A-Z][A-Z][A-Z]'')
);
CREATE TABLE transport.VehicleDocument(
 VehicleDocumentId uniqueidentifier NOT NULL CONSTRAINT DF_VehicleDocument_Id DEFAULT NEWSEQUENTIALID(),
 SchoolId uniqueidentifier NOT NULL,
 VehicleId uniqueidentifier NOT NULL,
 DocumentType varchar(50) NOT NULL,
 FileObjectId uniqueidentifier NOT NULL,
 ExpiresOn date NOT NULL,
 CONSTRAINT PK_VehicleDocument PRIMARY KEY(VehicleDocumentId),
 CONSTRAINT UQ_VehicleDocument_Scope UNIQUE(SchoolId,VehicleDocumentId),
 CONSTRAINT FK_VehicleDocument_School FOREIGN KEY(SchoolId) REFERENCES core.School(SchoolId),
 CONSTRAINT FK_VehicleDocument_Vehicle FOREIGN KEY(SchoolId,VehicleId) REFERENCES transport.Vehicle(SchoolId,VehicleId),
 CONSTRAINT FK_VehicleDocument_File FOREIGN KEY(SchoolId,FileObjectId) REFERENCES core.FileObject(SchoolId,FileObjectId)
);
CREATE TABLE operations.VisitorLog(
 VisitorLogId uniqueidentifier NOT NULL CONSTRAINT DF_VisitorLog_Id DEFAULT NEWSEQUENTIALID(),
 SchoolId uniqueidentifier NOT NULL,
 VisitorName nvarchar(200) NOT NULL,
 Purpose nvarchar(1000) NOT NULL,
 HostEmployeeId uniqueidentifier NOT NULL,
 ArrivedAtUtc datetime2(3) NOT NULL,
 DepartedAtUtc datetime2(3) NULL,
 RecordedByUserId uniqueidentifier NOT NULL,
 CONSTRAINT PK_VisitorLog PRIMARY KEY(VisitorLogId),
 CONSTRAINT UQ_VisitorLog_Scope UNIQUE(SchoolId,VisitorLogId),
 CONSTRAINT FK_VisitorLog_School FOREIGN KEY(SchoolId) REFERENCES core.School(SchoolId),
 CONSTRAINT FK_VisitorLog_Host FOREIGN KEY(SchoolId,HostEmployeeId) REFERENCES people.EmployeeProfile(SchoolId,EmployeeId),
 CONSTRAINT FK_VisitorLog_Recorder FOREIGN KEY(RecordedByUserId) REFERENCES security.UserAccount(UserId),
 CHECK(DepartedAtUtc IS NULL OR DepartedAtUtc>=ArrivedAtUtc)
);
CREATE TABLE health.StudentMedicalProfile(
 StudentMedicalProfileId uniqueidentifier NOT NULL CONSTRAINT DF_StudentMedicalProfile_Id DEFAULT NEWSEQUENTIALID(),
 SchoolId uniqueidentifier NOT NULL,
 StudentId uniqueidentifier NOT NULL,
 Allergies nvarchar(2000) NULL,
 ChronicConditions nvarchar(2000) NULL,
 EmergencyPlan nvarchar(3000) NULL,
 EmergencyContact nvarchar(300) NOT NULL,
 UpdatedByUserId uniqueidentifier NOT NULL,
 UpdatedAtUtc datetime2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
 CONSTRAINT PK_StudentMedicalProfile PRIMARY KEY(StudentMedicalProfileId),
 CONSTRAINT UQ_StudentMedicalProfile_Scope UNIQUE(SchoolId,StudentMedicalProfileId),
 CONSTRAINT FK_StudentMedicalProfile_School FOREIGN KEY(SchoolId) REFERENCES core.School(SchoolId),
 CONSTRAINT FK_StudentMedicalProfile_Student FOREIGN KEY(SchoolId,StudentId) REFERENCES people.StudentProfile(SchoolId,StudentId),
 CONSTRAINT FK_StudentMedicalProfile_Updater FOREIGN KEY(UpdatedByUserId) REFERENCES security.UserAccount(UserId),
 UNIQUE(SchoolId,StudentId)
);
CREATE TABLE hr.SalaryComponent(
 SalaryComponentId uniqueidentifier NOT NULL CONSTRAINT DF_SalaryComponent_Id DEFAULT NEWSEQUENTIALID(),
 SchoolId uniqueidentifier NOT NULL,
 Code nvarchar(50) NOT NULL,
 Name nvarchar(160) NOT NULL,
 ComponentType varchar(20) NOT NULL,
 CONSTRAINT PK_SalaryComponent PRIMARY KEY(SalaryComponentId),
 CONSTRAINT UQ_SalaryComponent_Scope UNIQUE(SchoolId,SalaryComponentId),
 CONSTRAINT FK_SalaryComponent_School FOREIGN KEY(SchoolId) REFERENCES core.School(SchoolId),
 UNIQUE(SchoolId,Code),
 CHECK(ComponentType IN (''earning'',''deduction''))
);
CREATE TABLE hr.EmployeeSalaryComponent(
 EmployeeSalaryComponentId uniqueidentifier NOT NULL CONSTRAINT DF_EmployeeSalaryComponent_Id DEFAULT NEWSEQUENTIALID(),
 SchoolId uniqueidentifier NOT NULL,
 EmployeeId uniqueidentifier NOT NULL,
 SalaryComponentId uniqueidentifier NOT NULL,
 EffectiveFrom date NOT NULL,
 EffectiveTo date NULL,
 Amount decimal(19,4) NOT NULL,
 CurrencyCode char(3) NOT NULL,
 CONSTRAINT PK_EmployeeSalaryComponent PRIMARY KEY(EmployeeSalaryComponentId),
 CONSTRAINT UQ_EmployeeSalaryComponent_Scope UNIQUE(SchoolId,EmployeeSalaryComponentId),
 CONSTRAINT FK_EmployeeSalaryComponent_School FOREIGN KEY(SchoolId) REFERENCES core.School(SchoolId),
 CONSTRAINT FK_EmployeeSalaryComponent_Employee FOREIGN KEY(SchoolId,EmployeeId) REFERENCES people.EmployeeProfile(SchoolId,EmployeeId),
 CONSTRAINT FK_EmployeeSalaryComponent_Component FOREIGN KEY(SchoolId,SalaryComponentId) REFERENCES hr.SalaryComponent(SchoolId,SalaryComponentId),
 CHECK(Amount>=0 AND (EffectiveTo IS NULL OR EffectiveTo>=EffectiveFrom) AND CurrencyCode LIKE ''[A-Z][A-Z][A-Z]'')
);
CREATE TABLE academic.CurriculumProgram(
 CurriculumProgramId uniqueidentifier NOT NULL CONSTRAINT DF_CurriculumProgram_Id DEFAULT NEWSEQUENTIALID(),
 SchoolId uniqueidentifier NOT NULL,
 Code nvarchar(50) NOT NULL,
 Name nvarchar(160) NOT NULL,
 CONSTRAINT PK_CurriculumProgram PRIMARY KEY(CurriculumProgramId),
 CONSTRAINT UQ_CurriculumProgram_Scope UNIQUE(SchoolId,CurriculumProgramId),
 CONSTRAINT FK_CurriculumProgram_School FOREIGN KEY(SchoolId) REFERENCES core.School(SchoolId),
 UNIQUE(SchoolId,Code)
);
CREATE TABLE academic.ProgramGrade(
 ProgramGradeId uniqueidentifier NOT NULL CONSTRAINT DF_ProgramGrade_Id DEFAULT NEWSEQUENTIALID(),
 SchoolId uniqueidentifier NOT NULL,
 CurriculumProgramId uniqueidentifier NOT NULL,
 GradeLevelId uniqueidentifier NOT NULL,
 CONSTRAINT PK_ProgramGrade PRIMARY KEY(ProgramGradeId),
 CONSTRAINT UQ_ProgramGrade_Scope UNIQUE(SchoolId,ProgramGradeId),
 CONSTRAINT FK_ProgramGrade_School FOREIGN KEY(SchoolId) REFERENCES core.School(SchoolId),
 CONSTRAINT FK_ProgramGrade_Program FOREIGN KEY(SchoolId,CurriculumProgramId) REFERENCES academic.CurriculumProgram(SchoolId,CurriculumProgramId),
 CONSTRAINT FK_ProgramGrade_Grade FOREIGN KEY(SchoolId,GradeLevelId) REFERENCES academic.GradeLevel(SchoolId,GradeLevelId),
 UNIQUE(SchoolId,CurriculumProgramId,GradeLevelId)
);
CREATE TABLE operations.ExportJob(
 ExportJobId uniqueidentifier NOT NULL CONSTRAINT DF_ExportJob_Id DEFAULT NEWSEQUENTIALID(),
 SchoolId uniqueidentifier NOT NULL,
 EntityType varchar(80) NOT NULL,
 FormatCode varchar(30) NOT NULL,
 FileObjectId uniqueidentifier NULL,
 RequestedByUserId uniqueidentifier NOT NULL,
 CreatedAtUtc datetime2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
 Status varchar(20) NOT NULL DEFAULT ''queued'',
 CONSTRAINT PK_ExportJob PRIMARY KEY(ExportJobId),
 CONSTRAINT UQ_ExportJob_Scope UNIQUE(SchoolId,ExportJobId),
 CONSTRAINT FK_ExportJob_School FOREIGN KEY(SchoolId) REFERENCES core.School(SchoolId),
 CONSTRAINT FK_ExportJob_File FOREIGN KEY(SchoolId,FileObjectId) REFERENCES core.FileObject(SchoolId,FileObjectId),
 CONSTRAINT FK_ExportJob_Requester FOREIGN KEY(RequestedByUserId) REFERENCES security.UserAccount(UserId),
 CHECK(Status IN (''queued'',''processing'',''completed'',''failed'',''cancelled''))
);

';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(14,N''014_operational_coverage.sql'',0xe930c5c421129e8967615153ba9f77e52ff642cb70e1cc7d11751c15be62fc50,''executed'');';
 -- BEGIN 015_platform_and_audiences.sql
 EXEC sys.sp_executesql N'SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;

CREATE TABLE core.LicensePlan(
 LicensePlanId uniqueidentifier NOT NULL CONSTRAINT DF_LicensePlan_Id DEFAULT NEWSEQUENTIALID(),
 Code nvarchar(50) NOT NULL,Name nvarchar(160) NOT NULL,
 MaximumSchools int NOT NULL,MaximumStudents int NOT NULL,
 CONSTRAINT PK_LicensePlan PRIMARY KEY(LicensePlanId),CONSTRAINT UQ_LicensePlan_Code UNIQUE(Code),
 CONSTRAINT CK_LicensePlan_Limits CHECK(MaximumSchools>0 AND MaximumStudents>0));
CREATE TABLE core.OrganizationLicense(
 OrganizationLicenseId uniqueidentifier NOT NULL CONSTRAINT DF_OrganizationLicense_Id DEFAULT NEWSEQUENTIALID(),
 OrganizationId uniqueidentifier NOT NULL,LicensePlanId uniqueidentifier NOT NULL,
 ValidFrom date NOT NULL,ValidTo date NOT NULL,Status varchar(20) NOT NULL,
 CONSTRAINT PK_OrganizationLicense PRIMARY KEY(OrganizationLicenseId),
 CONSTRAINT FK_OrganizationLicense_Organization FOREIGN KEY(OrganizationId) REFERENCES core.Organization(OrganizationId),
 CONSTRAINT FK_OrganizationLicense_Plan FOREIGN KEY(LicensePlanId) REFERENCES core.LicensePlan(LicensePlanId),
 CONSTRAINT CK_OrganizationLicense_Dates CHECK(ValidFrom<=ValidTo),CONSTRAINT CK_OrganizationLicense_Status CHECK(Status IN (''draft'',''active'',''suspended'',''expired'',''cancelled'')));
CREATE UNIQUE INDEX UX_OrganizationLicense_Active ON core.OrganizationLicense(OrganizationId) WHERE Status=''active'';
ALTER TABLE learning.Resource ADD TargetStageId uniqueidentifier NULL,TargetGradeLevelId uniqueidentifier NULL,TargetClassSectionId uniqueidentifier NULL,TargetTeachingAssignmentId uniqueidentifier NULL;
ALTER TABLE learning.Resource ADD
 CONSTRAINT FK_Resource_TargetStage FOREIGN KEY(SchoolId,TargetStageId) REFERENCES academic.Stage(SchoolId,StageId),
 CONSTRAINT FK_Resource_TargetGrade FOREIGN KEY(SchoolId,TargetGradeLevelId) REFERENCES academic.GradeLevel(SchoolId,GradeLevelId),
 CONSTRAINT FK_Resource_TargetClass FOREIGN KEY(SchoolId,TargetClassSectionId) REFERENCES academic.ClassSection(SchoolId,ClassSectionId),
 CONSTRAINT FK_Resource_TargetAssignment FOREIGN KEY(SchoolId,TargetTeachingAssignmentId) REFERENCES academic.TeachingAssignment(SchoolId,TeachingAssignmentId),
 CONSTRAINT CK_Resource_Target CHECK(
 (Visibility=''school'' AND TargetStageId IS NULL AND TargetGradeLevelId IS NULL AND TargetClassSectionId IS NULL AND TargetTeachingAssignmentId IS NULL) OR
 (Visibility=''stage'' AND TargetStageId IS NOT NULL AND TargetGradeLevelId IS NULL AND TargetClassSectionId IS NULL AND TargetTeachingAssignmentId IS NULL) OR
 (Visibility=''grade'' AND TargetStageId IS NULL AND TargetGradeLevelId IS NOT NULL AND TargetClassSectionId IS NULL AND TargetTeachingAssignmentId IS NULL) OR
 (Visibility=''class'' AND TargetStageId IS NULL AND TargetGradeLevelId IS NULL AND TargetClassSectionId IS NOT NULL AND TargetTeachingAssignmentId IS NULL) OR
 (Visibility=''assignment'' AND TargetStageId IS NULL AND TargetGradeLevelId IS NULL AND TargetClassSectionId IS NULL AND TargetTeachingAssignmentId IS NOT NULL));
ALTER TABLE learning.CircularAudience ADD RoleId smallint NULL;
ALTER TABLE learning.CircularAudience ADD CONSTRAINT FK_CircularAudience_Role FOREIGN KEY(RoleId) REFERENCES security.Role(RoleId),CONSTRAINT CK_CircularAudience_Role CHECK((AudienceType=''role'' AND RoleId IS NOT NULL) OR (AudienceType<>''role'' AND RoleId IS NULL));
CREATE TABLE learning.SubmissionRevisionFile(
 SchoolId uniqueidentifier NOT NULL,SubmissionRevisionId uniqueidentifier NOT NULL,FileObjectId uniqueidentifier NOT NULL,
 CONSTRAINT PK_SubmissionRevisionFile PRIMARY KEY(SchoolId,SubmissionRevisionId,FileObjectId),
 CONSTRAINT FK_SubmissionRevisionFile_File FOREIGN KEY(SchoolId,FileObjectId) REFERENCES core.FileObject(SchoolId,FileObjectId));
ALTER TABLE learning.SubmissionRevision ADD CONSTRAINT UQ_SubmissionRevision_Scope UNIQUE(SchoolId,SubmissionRevisionId);
ALTER TABLE learning.SubmissionRevisionFile ADD CONSTRAINT FK_SubmissionRevisionFile_Revision FOREIGN KEY(SchoolId,SubmissionRevisionId) REFERENCES learning.SubmissionRevision(SchoolId,SubmissionRevisionId);

';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(15,N''015_platform_and_audiences.sql'',0xbd2504aa90f1e70b2bb1c8002dfa5e2d8205a6703d342945628b6bba1557b7c6,''executed'');';
 -- BEGIN 016_operational_integrity.sql
 EXEC sys.sp_executesql N'SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;

EXEC(N''CREATE OR ALTER TRIGGER attendance.TR_LeaveUsage_CoverageIntegrity ON attendance.LeaveUsage AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM attendance.LeaveUsage x WITH(UPDLOCK,HOLDLOCK) JOIN attendance.LeaveEntitlement e WITH(UPDLOCK,HOLDLOCK) ON e.LeaveEntitlementId=x.LeaveEntitlementId JOIN attendance.LeaveRequest r WITH(UPDLOCK,HOLDLOCK) ON r.LeaveRequestId=x.LeaveRequestId WHERE (e.EmployeeId<>r.EmployeeId OR e.LeaveTypeCode<>r.LeaveTypeCode OR r.Status<>''''approved'''' OR r.StartDate<e.PeriodStart OR r.EndDate>e.PeriodEnd OR x.DaysUsed>DATEDIFF(day,r.StartDate,r.EndDate)+1) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52100,''''LeaveUsage invariant violated.'''',1;
IF EXISTS(SELECT 1 FROM attendance.LeaveEntitlement x WITH(UPDLOCK,HOLDLOCK) CROSS APPLY(SELECT SUM(u.DaysUsed) total FROM attendance.LeaveUsage u WITH(UPDLOCK,HOLDLOCK) WHERE u.LeaveEntitlementId=x.LeaveEntitlementId) u WHERE (u.total>x.EntitledDays) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52101,''''LeaveBalance invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER attendance.TR_LeaveEntitlement_CoverageIntegrity ON attendance.LeaveEntitlement AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM attendance.LeaveUsage x WITH(UPDLOCK,HOLDLOCK) JOIN attendance.LeaveEntitlement e WITH(UPDLOCK,HOLDLOCK) ON e.LeaveEntitlementId=x.LeaveEntitlementId JOIN attendance.LeaveRequest r WITH(UPDLOCK,HOLDLOCK) ON r.LeaveRequestId=x.LeaveRequestId WHERE (e.EmployeeId<>r.EmployeeId OR e.LeaveTypeCode<>r.LeaveTypeCode OR r.Status<>''''approved'''' OR r.StartDate<e.PeriodStart OR r.EndDate>e.PeriodEnd OR x.DaysUsed>DATEDIFF(day,r.StartDate,r.EndDate)+1) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52100,''''LeaveUsage invariant violated.'''',1;
IF EXISTS(SELECT 1 FROM attendance.LeaveEntitlement x WITH(UPDLOCK,HOLDLOCK) CROSS APPLY(SELECT SUM(u.DaysUsed) total FROM attendance.LeaveUsage u WITH(UPDLOCK,HOLDLOCK) WHERE u.LeaveEntitlementId=x.LeaveEntitlementId) u WHERE (u.total>x.EntitledDays) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52101,''''LeaveBalance invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER attendance.TR_LeaveRequest_CoverageIntegrity ON attendance.LeaveRequest AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM attendance.LeaveUsage x WITH(UPDLOCK,HOLDLOCK) JOIN attendance.LeaveEntitlement e WITH(UPDLOCK,HOLDLOCK) ON e.LeaveEntitlementId=x.LeaveEntitlementId JOIN attendance.LeaveRequest r WITH(UPDLOCK,HOLDLOCK) ON r.LeaveRequestId=x.LeaveRequestId WHERE (e.EmployeeId<>r.EmployeeId OR e.LeaveTypeCode<>r.LeaveTypeCode OR r.Status<>''''approved'''' OR r.StartDate<e.PeriodStart OR r.EndDate>e.PeriodEnd OR x.DaysUsed>DATEDIFF(day,r.StartDate,r.EndDate)+1) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52100,''''LeaveUsage invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER transport.TR_StudentRide_CoverageIntegrity ON transport.StudentRide AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM transport.StudentRide x WITH(UPDLOCK,HOLDLOCK) JOIN transport.RouteRun r WITH(UPDLOCK,HOLDLOCK) ON r.RouteRunId=x.RouteRunId JOIN transport.TransportEnrollment e WITH(UPDLOCK,HOLDLOCK) ON e.TransportEnrollmentId=x.TransportEnrollmentId WHERE (r.RouteId<>e.RouteId OR r.RunDate<e.ValidFrom OR (e.ValidTo IS NOT NULL AND r.RunDate>e.ValidTo)) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52102,''''RideRoute invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER transport.TR_RouteRun_CoverageIntegrity ON transport.RouteRun AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM transport.StudentRide x WITH(UPDLOCK,HOLDLOCK) JOIN transport.RouteRun r WITH(UPDLOCK,HOLDLOCK) ON r.RouteRunId=x.RouteRunId JOIN transport.TransportEnrollment e WITH(UPDLOCK,HOLDLOCK) ON e.TransportEnrollmentId=x.TransportEnrollmentId WHERE (r.RouteId<>e.RouteId OR r.RunDate<e.ValidFrom OR (e.ValidTo IS NOT NULL AND r.RunDate>e.ValidTo)) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52102,''''RideRoute invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER transport.TR_TransportEnrollment_CoverageIntegrity ON transport.TransportEnrollment AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM transport.StudentRide x WITH(UPDLOCK,HOLDLOCK) JOIN transport.RouteRun r WITH(UPDLOCK,HOLDLOCK) ON r.RouteRunId=x.RouteRunId JOIN transport.TransportEnrollment e WITH(UPDLOCK,HOLDLOCK) ON e.TransportEnrollmentId=x.TransportEnrollmentId WHERE (r.RouteId<>e.RouteId OR r.RunDate<e.ValidFrom OR (e.ValidTo IS NOT NULL AND r.RunDate>e.ValidTo)) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52102,''''RideRoute invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER operations.TR_BehaviorEntry_CoverageIntegrity ON operations.BehaviorEntry AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM operations.BehaviorEntry x WITH(UPDLOCK,HOLDLOCK) JOIN operations.BehaviorEntry r WITH(UPDLOCK,HOLDLOCK) ON r.BehaviorEntryId=x.ReversesBehaviorEntryId WHERE (r.StudentId<>x.StudentId OR r.Points<>-x.Points OR r.BehaviorCategoryId<>x.BehaviorCategoryId OR r.ReversesBehaviorEntryId IS NOT NULL) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52103,''''BehaviorReversal invariant violated.'''',1;
END;'');

';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(16,N''016_operational_integrity.sql'',0xed75b68f53d87ed9103222e5f6d3cfd2cf180510450fcbe31febde051e563590,''executed'');';
 -- BEGIN 017_operational_constraint_names.sql
 EXEC sys.sp_executesql N'SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @schema sysname,@table sysname,@old sysname,@new sysname,@kind varchar(2),@definition nvarchar(max),@qualified nvarchar(776);
DECLARE names CURSOR LOCAL FAST_FORWARD FOR
SELECT s.name,t.name,o.name,o.type,COALESCE(c.definition,COL_NAME(d.parent_object_id,d.parent_column_id),k.cols)
FROM sys.objects o JOIN sys.tables t ON t.object_id=o.parent_object_id JOIN sys.schemas s ON s.schema_id=t.schema_id
LEFT JOIN sys.check_constraints c ON c.object_id=o.object_id
LEFT JOIN sys.default_constraints d ON d.object_id=o.object_id
OUTER APPLY(SELECT STRING_AGG(CONVERT(nvarchar(max),COL_NAME(ic.object_id,ic.column_id)),N''_'') WITHIN GROUP(ORDER BY ic.key_ordinal) cols FROM sys.index_columns ic JOIN sys.key_constraints kc ON kc.parent_object_id=ic.object_id AND kc.unique_index_id=ic.index_id WHERE kc.object_id=o.object_id AND ic.key_ordinal>0) k
WHERE c.is_system_named=1 OR d.is_system_named=1 OR EXISTS(SELECT 1 FROM sys.key_constraints kc WHERE kc.object_id=o.object_id AND kc.is_system_named=1);
OPEN names; FETCH NEXT FROM names INTO @schema,@table,@old,@kind,@definition;
WHILE @@FETCH_STATUS=0 BEGIN
 SET @new=CONVERT(sysname,LEFT(@kind+''_''+@table,95)+''_''+LEFT(CONVERT(varchar(64),HASHBYTES(''SHA2_256'',@definition),2),16));
 SET @qualified=QUOTENAME(@schema)+N''.''+QUOTENAME(@old);
 IF @old<>@new EXEC sys.sp_rename @objname=@qualified,@newname=@new,@objtype=N''OBJECT'';
 FETCH NEXT FROM names INTO @schema,@table,@old,@kind,@definition;
END;
CLOSE names; DEALLOCATE names;

';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(17,N''017_operational_constraint_names.sql'',0xb8397fc1fee4ca0b7a3f63e05a79b69f70d1d732e7383cdd73a36236280f8481,''executed'');';
 -- BEGIN 018_final_business_rules.sql
 EXEC sys.sp_executesql N'SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;

EXEC(N''CREATE OR ALTER TRIGGER academic.TR_TimetableLesson_CoverageIntegrity ON academic.TimetableLesson AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM academic.TimetableLesson x WITH(UPDLOCK,HOLDLOCK) JOIN academic.TimetableLesson y WITH(UPDLOCK,HOLDLOCK) ON y.SchoolId=x.SchoolId AND y.SchoolYearId=x.SchoolYearId AND y.TermId=x.TermId AND y.DayOfWeek=x.DayOfWeek AND y.TimetableLessonId<>x.TimetableLessonId JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=x.TeachingAssignmentId JOIN academic.TeachingAssignment b WITH(UPDLOCK,HOLDLOCK) ON b.TeachingAssignmentId=y.TeachingAssignmentId JOIN academic.PeriodDefinition p WITH(UPDLOCK,HOLDLOCK) ON p.PeriodId=x.PeriodId JOIN academic.PeriodDefinition q WITH(UPDLOCK,HOLDLOCK) ON q.PeriodId=y.PeriodId WHERE (x.Status=''''active'''' AND y.Status=''''active'''' AND x.EffectiveFrom<=COALESCE(y.EffectiveTo,CONVERT(date,''''99991231'''')) AND y.EffectiveFrom<=COALESCE(x.EffectiveTo,CONVERT(date,''''99991231'''')) AND p.StartTime<q.EndTime AND q.StartTime<p.EndTime AND (a.EmployeeId=b.EmployeeId OR a.ClassSectionId=b.ClassSectionId OR (x.RoomId IS NOT NULL AND x.RoomId=y.RoomId))) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52200,''''TimetableConflict invariant violated.'''',1;
IF EXISTS(SELECT 1 FROM attendance.CoverAssignment x WITH(UPDLOCK,HOLDLOCK) JOIN attendance.LeaveRequest r WITH(UPDLOCK,HOLDLOCK) ON r.LeaveRequestId=x.LeaveRequestId JOIN academic.TimetableLesson t WITH(UPDLOCK,HOLDLOCK) ON t.TimetableLessonId=x.TimetableLessonId JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=t.TeachingAssignmentId WHERE (x.Status=''''active'''' AND (r.Status<>''''approved'''' OR r.EmployeeId<>a.EmployeeId OR x.SubstituteEmployeeId=a.EmployeeId OR x.CoverDate<r.StartDate OR x.CoverDate>r.EndDate OR x.CoverDate<t.EffectiveFrom OR x.CoverDate>COALESCE(t.EffectiveTo,CONVERT(date,''''99991231'''')) OR ((DATEDIFF(day,CONVERT(date,''''19000101''''),x.CoverDate)%7+7)%7+1)<>t.DayOfWeek)) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52201,''''CoverScope invariant violated.'''',1;
IF EXISTS(SELECT 1 FROM attendance.CoverAssignment x WITH(UPDLOCK,HOLDLOCK) JOIN academic.TimetableLesson t WITH(UPDLOCK,HOLDLOCK) ON t.TimetableLessonId=x.TimetableLessonId JOIN academic.PeriodDefinition p WITH(UPDLOCK,HOLDLOCK) ON p.PeriodId=t.PeriodId JOIN academic.TimetableLesson y WITH(UPDLOCK,HOLDLOCK) ON y.SchoolId=x.SchoolId AND y.DayOfWeek=t.DayOfWeek JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=y.TeachingAssignmentId JOIN academic.PeriodDefinition q WITH(UPDLOCK,HOLDLOCK) ON q.PeriodId=y.PeriodId WHERE (x.Status=''''active'''' AND y.Status=''''active'''' AND a.EmployeeId=x.SubstituteEmployeeId AND x.CoverDate BETWEEN y.EffectiveFrom AND COALESCE(y.EffectiveTo,CONVERT(date,''''99991231'''')) AND p.StartTime<q.EndTime AND q.StartTime<p.EndTime) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52202,''''CoverBusy invariant violated.'''',1;
IF EXISTS(SELECT 1 FROM attendance.CoverAssignment x WITH(UPDLOCK,HOLDLOCK) JOIN attendance.CoverAssignment y WITH(UPDLOCK,HOLDLOCK) ON y.SchoolId=x.SchoolId AND y.SubstituteEmployeeId=x.SubstituteEmployeeId AND y.CoverDate=x.CoverDate AND y.CoverAssignmentId<>x.CoverAssignmentId JOIN academic.TimetableLesson a WITH(UPDLOCK,HOLDLOCK) ON a.TimetableLessonId=x.TimetableLessonId JOIN academic.TimetableLesson b WITH(UPDLOCK,HOLDLOCK) ON b.TimetableLessonId=y.TimetableLessonId JOIN academic.PeriodDefinition p WITH(UPDLOCK,HOLDLOCK) ON p.PeriodId=a.PeriodId JOIN academic.PeriodDefinition q WITH(UPDLOCK,HOLDLOCK) ON q.PeriodId=b.PeriodId WHERE (x.Status=''''active'''' AND y.Status=''''active'''' AND p.StartTime<q.EndTime AND q.StartTime<p.EndTime) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52204,''''CoverDuplicate invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER academic.TR_TeachingAssignment_CoverageIntegrity ON academic.TeachingAssignment AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM academic.TimetableLesson x WITH(UPDLOCK,HOLDLOCK) JOIN academic.TimetableLesson y WITH(UPDLOCK,HOLDLOCK) ON y.SchoolId=x.SchoolId AND y.SchoolYearId=x.SchoolYearId AND y.TermId=x.TermId AND y.DayOfWeek=x.DayOfWeek AND y.TimetableLessonId<>x.TimetableLessonId JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=x.TeachingAssignmentId JOIN academic.TeachingAssignment b WITH(UPDLOCK,HOLDLOCK) ON b.TeachingAssignmentId=y.TeachingAssignmentId JOIN academic.PeriodDefinition p WITH(UPDLOCK,HOLDLOCK) ON p.PeriodId=x.PeriodId JOIN academic.PeriodDefinition q WITH(UPDLOCK,HOLDLOCK) ON q.PeriodId=y.PeriodId WHERE (x.Status=''''active'''' AND y.Status=''''active'''' AND x.EffectiveFrom<=COALESCE(y.EffectiveTo,CONVERT(date,''''99991231'''')) AND y.EffectiveFrom<=COALESCE(x.EffectiveTo,CONVERT(date,''''99991231'''')) AND p.StartTime<q.EndTime AND q.StartTime<p.EndTime AND (a.EmployeeId=b.EmployeeId OR a.ClassSectionId=b.ClassSectionId OR (x.RoomId IS NOT NULL AND x.RoomId=y.RoomId))) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52200,''''TimetableConflict invariant violated.'''',1;
IF EXISTS(SELECT 1 FROM attendance.CoverAssignment x WITH(UPDLOCK,HOLDLOCK) JOIN attendance.LeaveRequest r WITH(UPDLOCK,HOLDLOCK) ON r.LeaveRequestId=x.LeaveRequestId JOIN academic.TimetableLesson t WITH(UPDLOCK,HOLDLOCK) ON t.TimetableLessonId=x.TimetableLessonId JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=t.TeachingAssignmentId WHERE (x.Status=''''active'''' AND (r.Status<>''''approved'''' OR r.EmployeeId<>a.EmployeeId OR x.SubstituteEmployeeId=a.EmployeeId OR x.CoverDate<r.StartDate OR x.CoverDate>r.EndDate OR x.CoverDate<t.EffectiveFrom OR x.CoverDate>COALESCE(t.EffectiveTo,CONVERT(date,''''99991231'''')) OR ((DATEDIFF(day,CONVERT(date,''''19000101''''),x.CoverDate)%7+7)%7+1)<>t.DayOfWeek)) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52201,''''CoverScope invariant violated.'''',1;
IF EXISTS(SELECT 1 FROM attendance.CoverAssignment x WITH(UPDLOCK,HOLDLOCK) JOIN academic.TimetableLesson t WITH(UPDLOCK,HOLDLOCK) ON t.TimetableLessonId=x.TimetableLessonId JOIN academic.PeriodDefinition p WITH(UPDLOCK,HOLDLOCK) ON p.PeriodId=t.PeriodId JOIN academic.TimetableLesson y WITH(UPDLOCK,HOLDLOCK) ON y.SchoolId=x.SchoolId AND y.DayOfWeek=t.DayOfWeek JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=y.TeachingAssignmentId JOIN academic.PeriodDefinition q WITH(UPDLOCK,HOLDLOCK) ON q.PeriodId=y.PeriodId WHERE (x.Status=''''active'''' AND y.Status=''''active'''' AND a.EmployeeId=x.SubstituteEmployeeId AND x.CoverDate BETWEEN y.EffectiveFrom AND COALESCE(y.EffectiveTo,CONVERT(date,''''99991231'''')) AND p.StartTime<q.EndTime AND q.StartTime<p.EndTime) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52202,''''CoverBusy invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER academic.TR_PeriodDefinition_CoverageIntegrity ON academic.PeriodDefinition AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM academic.TimetableLesson x WITH(UPDLOCK,HOLDLOCK) JOIN academic.TimetableLesson y WITH(UPDLOCK,HOLDLOCK) ON y.SchoolId=x.SchoolId AND y.SchoolYearId=x.SchoolYearId AND y.TermId=x.TermId AND y.DayOfWeek=x.DayOfWeek AND y.TimetableLessonId<>x.TimetableLessonId JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=x.TeachingAssignmentId JOIN academic.TeachingAssignment b WITH(UPDLOCK,HOLDLOCK) ON b.TeachingAssignmentId=y.TeachingAssignmentId JOIN academic.PeriodDefinition p WITH(UPDLOCK,HOLDLOCK) ON p.PeriodId=x.PeriodId JOIN academic.PeriodDefinition q WITH(UPDLOCK,HOLDLOCK) ON q.PeriodId=y.PeriodId WHERE (x.Status=''''active'''' AND y.Status=''''active'''' AND x.EffectiveFrom<=COALESCE(y.EffectiveTo,CONVERT(date,''''99991231'''')) AND y.EffectiveFrom<=COALESCE(x.EffectiveTo,CONVERT(date,''''99991231'''')) AND p.StartTime<q.EndTime AND q.StartTime<p.EndTime AND (a.EmployeeId=b.EmployeeId OR a.ClassSectionId=b.ClassSectionId OR (x.RoomId IS NOT NULL AND x.RoomId=y.RoomId))) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52200,''''TimetableConflict invariant violated.'''',1;
IF EXISTS(SELECT 1 FROM attendance.CoverAssignment x WITH(UPDLOCK,HOLDLOCK) JOIN academic.TimetableLesson t WITH(UPDLOCK,HOLDLOCK) ON t.TimetableLessonId=x.TimetableLessonId JOIN academic.PeriodDefinition p WITH(UPDLOCK,HOLDLOCK) ON p.PeriodId=t.PeriodId JOIN academic.TimetableLesson y WITH(UPDLOCK,HOLDLOCK) ON y.SchoolId=x.SchoolId AND y.DayOfWeek=t.DayOfWeek JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=y.TeachingAssignmentId JOIN academic.PeriodDefinition q WITH(UPDLOCK,HOLDLOCK) ON q.PeriodId=y.PeriodId WHERE (x.Status=''''active'''' AND y.Status=''''active'''' AND a.EmployeeId=x.SubstituteEmployeeId AND x.CoverDate BETWEEN y.EffectiveFrom AND COALESCE(y.EffectiveTo,CONVERT(date,''''99991231'''')) AND p.StartTime<q.EndTime AND q.StartTime<p.EndTime) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52202,''''CoverBusy invariant violated.'''',1;
IF EXISTS(SELECT 1 FROM attendance.CoverAssignment x WITH(UPDLOCK,HOLDLOCK) JOIN attendance.CoverAssignment y WITH(UPDLOCK,HOLDLOCK) ON y.SchoolId=x.SchoolId AND y.SubstituteEmployeeId=x.SubstituteEmployeeId AND y.CoverDate=x.CoverDate AND y.CoverAssignmentId<>x.CoverAssignmentId JOIN academic.TimetableLesson a WITH(UPDLOCK,HOLDLOCK) ON a.TimetableLessonId=x.TimetableLessonId JOIN academic.TimetableLesson b WITH(UPDLOCK,HOLDLOCK) ON b.TimetableLessonId=y.TimetableLessonId JOIN academic.PeriodDefinition p WITH(UPDLOCK,HOLDLOCK) ON p.PeriodId=a.PeriodId JOIN academic.PeriodDefinition q WITH(UPDLOCK,HOLDLOCK) ON q.PeriodId=b.PeriodId WHERE (x.Status=''''active'''' AND y.Status=''''active'''' AND p.StartTime<q.EndTime AND q.StartTime<p.EndTime) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52204,''''CoverDuplicate invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER attendance.TR_CoverAssignment_CoverageIntegrity ON attendance.CoverAssignment AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM attendance.CoverAssignment x WITH(UPDLOCK,HOLDLOCK) JOIN attendance.LeaveRequest r WITH(UPDLOCK,HOLDLOCK) ON r.LeaveRequestId=x.LeaveRequestId JOIN academic.TimetableLesson t WITH(UPDLOCK,HOLDLOCK) ON t.TimetableLessonId=x.TimetableLessonId JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=t.TeachingAssignmentId WHERE (x.Status=''''active'''' AND (r.Status<>''''approved'''' OR r.EmployeeId<>a.EmployeeId OR x.SubstituteEmployeeId=a.EmployeeId OR x.CoverDate<r.StartDate OR x.CoverDate>r.EndDate OR x.CoverDate<t.EffectiveFrom OR x.CoverDate>COALESCE(t.EffectiveTo,CONVERT(date,''''99991231'''')) OR ((DATEDIFF(day,CONVERT(date,''''19000101''''),x.CoverDate)%7+7)%7+1)<>t.DayOfWeek)) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52201,''''CoverScope invariant violated.'''',1;
IF EXISTS(SELECT 1 FROM attendance.CoverAssignment x WITH(UPDLOCK,HOLDLOCK) JOIN academic.TimetableLesson t WITH(UPDLOCK,HOLDLOCK) ON t.TimetableLessonId=x.TimetableLessonId JOIN academic.PeriodDefinition p WITH(UPDLOCK,HOLDLOCK) ON p.PeriodId=t.PeriodId JOIN academic.TimetableLesson y WITH(UPDLOCK,HOLDLOCK) ON y.SchoolId=x.SchoolId AND y.DayOfWeek=t.DayOfWeek JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=y.TeachingAssignmentId JOIN academic.PeriodDefinition q WITH(UPDLOCK,HOLDLOCK) ON q.PeriodId=y.PeriodId WHERE (x.Status=''''active'''' AND y.Status=''''active'''' AND a.EmployeeId=x.SubstituteEmployeeId AND x.CoverDate BETWEEN y.EffectiveFrom AND COALESCE(y.EffectiveTo,CONVERT(date,''''99991231'''')) AND p.StartTime<q.EndTime AND q.StartTime<p.EndTime) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52202,''''CoverBusy invariant violated.'''',1;
IF EXISTS(SELECT 1 FROM attendance.CoverAssignment x WITH(UPDLOCK,HOLDLOCK) JOIN attendance.LeaveRequest r WITH(UPDLOCK,HOLDLOCK) ON r.SchoolId=x.SchoolId AND r.EmployeeId=x.SubstituteEmployeeId WHERE (x.Status=''''active'''' AND r.Status=''''approved'''' AND x.CoverDate BETWEEN r.StartDate AND r.EndDate) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52203,''''CoverLeave invariant violated.'''',1;
IF EXISTS(SELECT 1 FROM attendance.CoverAssignment x WITH(UPDLOCK,HOLDLOCK) JOIN attendance.CoverAssignment y WITH(UPDLOCK,HOLDLOCK) ON y.SchoolId=x.SchoolId AND y.SubstituteEmployeeId=x.SubstituteEmployeeId AND y.CoverDate=x.CoverDate AND y.CoverAssignmentId<>x.CoverAssignmentId JOIN academic.TimetableLesson a WITH(UPDLOCK,HOLDLOCK) ON a.TimetableLessonId=x.TimetableLessonId JOIN academic.TimetableLesson b WITH(UPDLOCK,HOLDLOCK) ON b.TimetableLessonId=y.TimetableLessonId JOIN academic.PeriodDefinition p WITH(UPDLOCK,HOLDLOCK) ON p.PeriodId=a.PeriodId JOIN academic.PeriodDefinition q WITH(UPDLOCK,HOLDLOCK) ON q.PeriodId=b.PeriodId WHERE (x.Status=''''active'''' AND y.Status=''''active'''' AND p.StartTime<q.EndTime AND q.StartTime<p.EndTime) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52204,''''CoverDuplicate invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER attendance.TR_LeaveRequest_CoverageIntegrity ON attendance.LeaveRequest AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM attendance.CoverAssignment x WITH(UPDLOCK,HOLDLOCK) JOIN attendance.LeaveRequest r WITH(UPDLOCK,HOLDLOCK) ON r.LeaveRequestId=x.LeaveRequestId JOIN academic.TimetableLesson t WITH(UPDLOCK,HOLDLOCK) ON t.TimetableLessonId=x.TimetableLessonId JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=t.TeachingAssignmentId WHERE (x.Status=''''active'''' AND (r.Status<>''''approved'''' OR r.EmployeeId<>a.EmployeeId OR x.SubstituteEmployeeId=a.EmployeeId OR x.CoverDate<r.StartDate OR x.CoverDate>r.EndDate OR x.CoverDate<t.EffectiveFrom OR x.CoverDate>COALESCE(t.EffectiveTo,CONVERT(date,''''99991231'''')) OR ((DATEDIFF(day,CONVERT(date,''''19000101''''),x.CoverDate)%7+7)%7+1)<>t.DayOfWeek)) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52201,''''CoverScope invariant violated.'''',1;
IF EXISTS(SELECT 1 FROM attendance.CoverAssignment x WITH(UPDLOCK,HOLDLOCK) JOIN attendance.LeaveRequest r WITH(UPDLOCK,HOLDLOCK) ON r.SchoolId=x.SchoolId AND r.EmployeeId=x.SubstituteEmployeeId WHERE (x.Status=''''active'''' AND r.Status=''''approved'''' AND x.CoverDate BETWEEN r.StartDate AND r.EndDate) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52203,''''CoverLeave invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER hr.TR_PayrollRun_CoverageIntegrity ON hr.PayrollRun AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM hr.PayrollRunLine x WITH(UPDLOCK,HOLDLOCK) JOIN hr.PayrollRun r WITH(UPDLOCK,HOLDLOCK) ON r.PayrollRunId=x.PayrollRunId WHERE (x.CurrencyCode<>r.CurrencyCode) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52205,''''PayrollCurrency invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER hr.TR_PayrollRunLine_CoverageIntegrity ON hr.PayrollRunLine AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM hr.PayrollRunLine x WITH(UPDLOCK,HOLDLOCK) JOIN hr.PayrollRun r WITH(UPDLOCK,HOLDLOCK) ON r.PayrollRunId=x.PayrollRunId WHERE (x.CurrencyCode<>r.CurrencyCode) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52205,''''PayrollCurrency invariant violated.'''',1;
END;'');

';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(18,N''018_final_business_rules.sql'',0x9b4fe9b90f7b2fd4d054e8e0cd48181a184d2e1890b742e82db8a203e7a3f13a,''executed'');';
 -- BEGIN 019_history_and_licenses.sql
 EXEC sys.sp_executesql N'SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER TRIGGER hr.TR_PayrollLine_Frozen ON hr.PayrollRunLine AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; IF EXISTS(SELECT 1 FROM hr.PayrollRun r WITH(UPDLOCK,HOLDLOCK) JOIN (SELECT PayrollRunId FROM inserted UNION SELECT PayrollRunId FROM deleted) x ON x.PayrollRunId=r.PayrollRunId WHERE r.Status IN (''approved'',''paid'')) THROW 52300,''Approved payroll lines are frozen.'',1; END;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER TRIGGER hr.TR_PayrollRun_Frozen ON hr.PayrollRun AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; IF EXISTS(SELECT 1 FROM deleted d LEFT JOIN inserted i ON i.PayrollRunId=d.PayrollRunId WHERE d.Status IN (''approved'',''paid'') AND (i.PayrollRunId IS NULL OR i.PeriodStart<>d.PeriodStart OR i.PeriodEnd<>d.PeriodEnd OR i.CurrencyCode<>d.CurrencyCode OR i.SchoolId<>d.SchoolId OR i.RunNo<>d.RunNo OR i.Status NOT IN (''approved'',''paid'') OR d.Status=''paid'' AND i.Status<>''paid'')) THROW 52301,''Approved payroll identity and accounting period are frozen.'',1; END;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER TRIGGER assessment.TR_Question_Frozen ON assessment.Question AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; IF EXISTS(SELECT 1 FROM deleted d JOIN assessment.ExamQuestion q WITH(UPDLOCK,HOLDLOCK) ON q.QuestionId=d.QuestionId JOIN assessment.Exam e WITH(UPDLOCK,HOLDLOCK) ON e.ExamId=q.ExamId WHERE e.Status<>''draft'') THROW 52302,''Version a question instead of modifying a released question.'',1; END;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER TRIGGER assessment.TR_QuestionOption_Frozen ON assessment.QuestionOption AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; IF EXISTS(SELECT 1 FROM (SELECT QuestionId FROM inserted UNION SELECT QuestionId FROM deleted) x JOIN assessment.ExamQuestion q WITH(UPDLOCK,HOLDLOCK) ON q.QuestionId=x.QuestionId JOIN assessment.Exam e WITH(UPDLOCK,HOLDLOCK) ON e.ExamId=q.ExamId WHERE e.Status<>''draft'') THROW 52302,''Released question options are frozen.'',1; END;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER TRIGGER learning.TR_RubricCriterion_Frozen ON learning.RubricCriterion AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; IF EXISTS(SELECT 1 FROM (SELECT RubricId FROM inserted UNION SELECT RubricId FROM deleted) x JOIN learning.Rubric r WITH(UPDLOCK,HOLDLOCK) ON r.RubricId=x.RubricId WHERE r.Status<>''draft'') THROW 52303,''Version the rubric instead of changing approved criteria.'',1; END;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER TRIGGER learning.TR_VisitRating_Frozen ON learning.VisitRating AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; IF EXISTS(SELECT 1 FROM (SELECT SupervisoryVisitId FROM inserted UNION SELECT SupervisoryVisitId FROM deleted) x JOIN learning.SupervisoryVisit v WITH(UPDLOCK,HOLDLOCK) ON v.SupervisoryVisitId=x.SupervisoryVisitId WHERE v.Status=''completed'') THROW 52304,''Completed visit ratings are frozen.'',1; END;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER TRIGGER core.TR_OrganizationLicense_LicenseCapacity ON core.OrganizationLicense AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON;
IF EXISTS(SELECT 1 FROM core.OrganizationLicense l WITH(UPDLOCK,HOLDLOCK) JOIN core.LicensePlan p WITH(UPDLOCK,HOLDLOCK) ON p.LicensePlanId=l.LicensePlanId OUTER APPLY(SELECT COUNT_BIG(*) n FROM core.School s WITH(UPDLOCK,HOLDLOCK) WHERE s.OrganizationId=l.OrganizationId) sc OUTER APPLY(SELECT COUNT_BIG(*) n FROM people.StudentProfile st WITH(UPDLOCK,HOLDLOCK) JOIN core.School s WITH(UPDLOCK,HOLDLOCK) ON s.SchoolId=st.SchoolId WHERE s.OrganizationId=l.OrganizationId) st WHERE l.Status=''active'' AND (sc.n>p.MaximumSchools OR st.n>p.MaximumStudents)) THROW 52305,''Active license capacity exceeded.'',1;
END;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER TRIGGER core.TR_LicensePlan_LicenseCapacity ON core.LicensePlan AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON;
IF EXISTS(SELECT 1 FROM core.OrganizationLicense l WITH(UPDLOCK,HOLDLOCK) JOIN core.LicensePlan p WITH(UPDLOCK,HOLDLOCK) ON p.LicensePlanId=l.LicensePlanId OUTER APPLY(SELECT COUNT_BIG(*) n FROM core.School s WITH(UPDLOCK,HOLDLOCK) WHERE s.OrganizationId=l.OrganizationId) sc OUTER APPLY(SELECT COUNT_BIG(*) n FROM people.StudentProfile st WITH(UPDLOCK,HOLDLOCK) JOIN core.School s WITH(UPDLOCK,HOLDLOCK) ON s.SchoolId=st.SchoolId WHERE s.OrganizationId=l.OrganizationId) st WHERE l.Status=''active'' AND (sc.n>p.MaximumSchools OR st.n>p.MaximumStudents)) THROW 52305,''Active license capacity exceeded.'',1;
END;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER TRIGGER core.TR_School_LicenseCapacity ON core.School AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON;
IF EXISTS(SELECT 1 FROM core.OrganizationLicense l WITH(UPDLOCK,HOLDLOCK) JOIN core.LicensePlan p WITH(UPDLOCK,HOLDLOCK) ON p.LicensePlanId=l.LicensePlanId OUTER APPLY(SELECT COUNT_BIG(*) n FROM core.School s WITH(UPDLOCK,HOLDLOCK) WHERE s.OrganizationId=l.OrganizationId) sc OUTER APPLY(SELECT COUNT_BIG(*) n FROM people.StudentProfile st WITH(UPDLOCK,HOLDLOCK) JOIN core.School s WITH(UPDLOCK,HOLDLOCK) ON s.SchoolId=st.SchoolId WHERE s.OrganizationId=l.OrganizationId) st WHERE l.Status=''active'' AND (sc.n>p.MaximumSchools OR st.n>p.MaximumStudents)) THROW 52305,''Active license capacity exceeded.'',1;
END;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER TRIGGER people.TR_StudentProfile_LicenseCapacity ON people.StudentProfile AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON;
IF EXISTS(SELECT 1 FROM core.OrganizationLicense l WITH(UPDLOCK,HOLDLOCK) JOIN core.LicensePlan p WITH(UPDLOCK,HOLDLOCK) ON p.LicensePlanId=l.LicensePlanId OUTER APPLY(SELECT COUNT_BIG(*) n FROM core.School s WITH(UPDLOCK,HOLDLOCK) WHERE s.OrganizationId=l.OrganizationId) sc OUTER APPLY(SELECT COUNT_BIG(*) n FROM people.StudentProfile st WITH(UPDLOCK,HOLDLOCK) JOIN core.School s WITH(UPDLOCK,HOLDLOCK) ON s.SchoolId=st.SchoolId WHERE s.OrganizationId=l.OrganizationId) st WHERE l.Status=''active'' AND (sc.n>p.MaximumSchools OR st.n>p.MaximumStudents)) THROW 52305,''Active license capacity exceeded.'',1;
END;
';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(19,N''019_history_and_licenses.sql'',0x7b20f3e0c6947fcade3d9cfe86cae00c4449b84c6c03574f5521540a23c68ed4,''executed'');';
 -- BEGIN 020_preserve_domain_guards.sql
 EXEC sys.sp_executesql N'-- Restore independent guard sets; final rules use a distinct trigger namespace.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;

EXEC(N''CREATE OR ALTER TRIGGER learning.TR_VisitRating_CoverageIntegrity ON learning.VisitRating AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM learning.VisitRating x WITH(UPDLOCK,HOLDLOCK) JOIN learning.RubricCriterion c WITH(UPDLOCK,HOLDLOCK) ON c.RubricCriterionId=x.RubricCriterionId WHERE (x.Score>c.MaximumScore) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52000,''''VisitScore invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER learning.TR_RubricCriterion_CoverageIntegrity ON learning.RubricCriterion AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM learning.VisitRating x WITH(UPDLOCK,HOLDLOCK) JOIN learning.RubricCriterion c WITH(UPDLOCK,HOLDLOCK) ON c.RubricCriterionId=x.RubricCriterionId WHERE (x.Score>c.MaximumScore) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52000,''''VisitScore invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER assessment.TR_ExamResponse_CoverageIntegrity ON assessment.ExamResponse AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM assessment.ExamResponse x WITH(UPDLOCK,HOLDLOCK) JOIN assessment.ExamQuestion q WITH(UPDLOCK,HOLDLOCK) ON q.ExamQuestionId=x.ExamQuestionId WHERE (x.Score>q.MaximumScore) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52001,''''ExamScore invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER assessment.TR_ExamQuestion_CoverageIntegrity ON assessment.ExamQuestion AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM assessment.ExamResponse x WITH(UPDLOCK,HOLDLOCK) JOIN assessment.ExamQuestion q WITH(UPDLOCK,HOLDLOCK) ON q.ExamQuestionId=x.ExamQuestionId WHERE (x.Score>q.MaximumScore) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52001,''''ExamScore invariant violated.'''',1;
IF EXISTS(SELECT 1 FROM assessment.ExamQuestion x WITH(UPDLOCK,HOLDLOCK) JOIN assessment.Exam e WITH(UPDLOCK,HOLDLOCK) ON e.ExamId=x.ExamId JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=e.TeachingAssignmentId JOIN assessment.Question q WITH(UPDLOCK,HOLDLOCK) ON q.QuestionId=x.QuestionId WHERE (a.SubjectId<>q.SubjectId) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52005,''''ExamSubject invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER assessment.TR_ExamAttempt_CoverageIntegrity ON assessment.ExamAttempt AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM assessment.ExamAttempt x WITH(UPDLOCK,HOLDLOCK) JOIN assessment.Exam e WITH(UPDLOCK,HOLDLOCK) ON e.ExamId=x.ExamId JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=e.TeachingAssignmentId JOIN people.StudentEnrollment n WITH(UPDLOCK,HOLDLOCK) ON n.EnrollmentId=x.EnrollmentId WHERE (n.ClassSectionId<>a.ClassSectionId OR n.SchoolYearId<>a.SchoolYearId OR x.AttemptNo>e.MaximumAttempts OR x.StartedAtUtc<e.OpensAtUtc OR x.StartedAtUtc>=e.ClosesAtUtc) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52002,''''ExamEnrollment invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER assessment.TR_Exam_CoverageIntegrity ON assessment.Exam AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM assessment.ExamAttempt x WITH(UPDLOCK,HOLDLOCK) JOIN assessment.Exam e WITH(UPDLOCK,HOLDLOCK) ON e.ExamId=x.ExamId JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=e.TeachingAssignmentId JOIN people.StudentEnrollment n WITH(UPDLOCK,HOLDLOCK) ON n.EnrollmentId=x.EnrollmentId WHERE (n.ClassSectionId<>a.ClassSectionId OR n.SchoolYearId<>a.SchoolYearId OR x.AttemptNo>e.MaximumAttempts OR x.StartedAtUtc<e.OpensAtUtc OR x.StartedAtUtc>=e.ClosesAtUtc) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52002,''''ExamEnrollment invariant violated.'''',1;
IF EXISTS(SELECT 1 FROM assessment.ExamQuestion x WITH(UPDLOCK,HOLDLOCK) JOIN assessment.Exam e WITH(UPDLOCK,HOLDLOCK) ON e.ExamId=x.ExamId JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=e.TeachingAssignmentId JOIN assessment.Question q WITH(UPDLOCK,HOLDLOCK) ON q.QuestionId=x.QuestionId WHERE (a.SubjectId<>q.SubjectId) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52005,''''ExamSubject invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER academic.TR_TeachingAssignment_CoverageIntegrity ON academic.TeachingAssignment AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM assessment.ExamAttempt x WITH(UPDLOCK,HOLDLOCK) JOIN assessment.Exam e WITH(UPDLOCK,HOLDLOCK) ON e.ExamId=x.ExamId JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=e.TeachingAssignmentId JOIN people.StudentEnrollment n WITH(UPDLOCK,HOLDLOCK) ON n.EnrollmentId=x.EnrollmentId WHERE (n.ClassSectionId<>a.ClassSectionId OR n.SchoolYearId<>a.SchoolYearId OR x.AttemptNo>e.MaximumAttempts OR x.StartedAtUtc<e.OpensAtUtc OR x.StartedAtUtc>=e.ClosesAtUtc) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52002,''''ExamEnrollment invariant violated.'''',1;
IF EXISTS(SELECT 1 FROM assessment.ExamQuestion x WITH(UPDLOCK,HOLDLOCK) JOIN assessment.Exam e WITH(UPDLOCK,HOLDLOCK) ON e.ExamId=x.ExamId JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=e.TeachingAssignmentId JOIN assessment.Question q WITH(UPDLOCK,HOLDLOCK) ON q.QuestionId=x.QuestionId WHERE (a.SubjectId<>q.SubjectId) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52005,''''ExamSubject invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER people.TR_StudentEnrollment_CoverageIntegrity ON people.StudentEnrollment AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM assessment.ExamAttempt x WITH(UPDLOCK,HOLDLOCK) JOIN assessment.Exam e WITH(UPDLOCK,HOLDLOCK) ON e.ExamId=x.ExamId JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=e.TeachingAssignmentId JOIN people.StudentEnrollment n WITH(UPDLOCK,HOLDLOCK) ON n.EnrollmentId=x.EnrollmentId WHERE (n.ClassSectionId<>a.ClassSectionId OR n.SchoolYearId<>a.SchoolYearId OR x.AttemptNo>e.MaximumAttempts OR x.StartedAtUtc<e.OpensAtUtc OR x.StartedAtUtc>=e.ClosesAtUtc) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52002,''''ExamEnrollment invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER operations.TR_OfficeHourSlot_CoverageIntegrity ON operations.OfficeHourSlot AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM operations.OfficeHourSlot x WITH(UPDLOCK,HOLDLOCK) JOIN operations.OfficeHourSlot y WITH(UPDLOCK,HOLDLOCK) ON y.SchoolId=x.SchoolId AND y.EmployeeId=x.EmployeeId AND y.OfficeHourSlotId<>x.OfficeHourSlotId WHERE (x.Status<>''''cancelled'''' AND y.Status<>''''cancelled'''' AND x.StartsAtUtc<y.EndsAtUtc AND y.StartsAtUtc<x.EndsAtUtc) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52003,''''SlotOverlap invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER operations.TR_Appointment_CoverageIntegrity ON operations.Appointment AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM operations.Appointment x WITH(UPDLOCK,HOLDLOCK) WHERE (x.Status<>''''cancelled'''' AND NOT EXISTS(SELECT 1 FROM people.StudentGuardian g WITH(UPDLOCK,HOLDLOCK) WHERE g.SchoolId=x.SchoolId AND g.StudentId=x.StudentId AND g.GuardianId=x.GuardianId AND g.Status=''''active'''')) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52004,''''AppointmentGuardian invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER people.TR_StudentGuardian_CoverageIntegrity ON people.StudentGuardian AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM operations.Appointment x WITH(UPDLOCK,HOLDLOCK) WHERE (x.Status<>''''cancelled'''' AND NOT EXISTS(SELECT 1 FROM people.StudentGuardian g WITH(UPDLOCK,HOLDLOCK) WHERE g.SchoolId=x.SchoolId AND g.StudentId=x.StudentId AND g.GuardianId=x.GuardianId AND g.Status=''''active'''')) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52004,''''AppointmentGuardian invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER assessment.TR_Question_CoverageIntegrity ON assessment.Question AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM assessment.ExamQuestion x WITH(UPDLOCK,HOLDLOCK) JOIN assessment.Exam e WITH(UPDLOCK,HOLDLOCK) ON e.ExamId=x.ExamId JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=e.TeachingAssignmentId JOIN assessment.Question q WITH(UPDLOCK,HOLDLOCK) ON q.QuestionId=x.QuestionId WHERE (a.SubjectId<>q.SubjectId) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52005,''''ExamSubject invariant violated.'''',1;
END;'');

';
 EXEC sys.sp_executesql N'
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;

EXEC(N''CREATE OR ALTER TRIGGER attendance.TR_LeaveUsage_CoverageIntegrity ON attendance.LeaveUsage AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM attendance.LeaveUsage x WITH(UPDLOCK,HOLDLOCK) JOIN attendance.LeaveEntitlement e WITH(UPDLOCK,HOLDLOCK) ON e.LeaveEntitlementId=x.LeaveEntitlementId JOIN attendance.LeaveRequest r WITH(UPDLOCK,HOLDLOCK) ON r.LeaveRequestId=x.LeaveRequestId WHERE (e.EmployeeId<>r.EmployeeId OR e.LeaveTypeCode<>r.LeaveTypeCode OR r.Status<>''''approved'''' OR r.StartDate<e.PeriodStart OR r.EndDate>e.PeriodEnd OR x.DaysUsed>DATEDIFF(day,r.StartDate,r.EndDate)+1) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52100,''''LeaveUsage invariant violated.'''',1;
IF EXISTS(SELECT 1 FROM attendance.LeaveEntitlement x WITH(UPDLOCK,HOLDLOCK) CROSS APPLY(SELECT SUM(u.DaysUsed) total FROM attendance.LeaveUsage u WITH(UPDLOCK,HOLDLOCK) WHERE u.LeaveEntitlementId=x.LeaveEntitlementId) u WHERE (u.total>x.EntitledDays) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52101,''''LeaveBalance invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER attendance.TR_LeaveEntitlement_CoverageIntegrity ON attendance.LeaveEntitlement AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM attendance.LeaveUsage x WITH(UPDLOCK,HOLDLOCK) JOIN attendance.LeaveEntitlement e WITH(UPDLOCK,HOLDLOCK) ON e.LeaveEntitlementId=x.LeaveEntitlementId JOIN attendance.LeaveRequest r WITH(UPDLOCK,HOLDLOCK) ON r.LeaveRequestId=x.LeaveRequestId WHERE (e.EmployeeId<>r.EmployeeId OR e.LeaveTypeCode<>r.LeaveTypeCode OR r.Status<>''''approved'''' OR r.StartDate<e.PeriodStart OR r.EndDate>e.PeriodEnd OR x.DaysUsed>DATEDIFF(day,r.StartDate,r.EndDate)+1) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52100,''''LeaveUsage invariant violated.'''',1;
IF EXISTS(SELECT 1 FROM attendance.LeaveEntitlement x WITH(UPDLOCK,HOLDLOCK) CROSS APPLY(SELECT SUM(u.DaysUsed) total FROM attendance.LeaveUsage u WITH(UPDLOCK,HOLDLOCK) WHERE u.LeaveEntitlementId=x.LeaveEntitlementId) u WHERE (u.total>x.EntitledDays) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52101,''''LeaveBalance invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER attendance.TR_LeaveRequest_CoverageIntegrity ON attendance.LeaveRequest AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM attendance.LeaveUsage x WITH(UPDLOCK,HOLDLOCK) JOIN attendance.LeaveEntitlement e WITH(UPDLOCK,HOLDLOCK) ON e.LeaveEntitlementId=x.LeaveEntitlementId JOIN attendance.LeaveRequest r WITH(UPDLOCK,HOLDLOCK) ON r.LeaveRequestId=x.LeaveRequestId WHERE (e.EmployeeId<>r.EmployeeId OR e.LeaveTypeCode<>r.LeaveTypeCode OR r.Status<>''''approved'''' OR r.StartDate<e.PeriodStart OR r.EndDate>e.PeriodEnd OR x.DaysUsed>DATEDIFF(day,r.StartDate,r.EndDate)+1) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52100,''''LeaveUsage invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER transport.TR_StudentRide_CoverageIntegrity ON transport.StudentRide AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM transport.StudentRide x WITH(UPDLOCK,HOLDLOCK) JOIN transport.RouteRun r WITH(UPDLOCK,HOLDLOCK) ON r.RouteRunId=x.RouteRunId JOIN transport.TransportEnrollment e WITH(UPDLOCK,HOLDLOCK) ON e.TransportEnrollmentId=x.TransportEnrollmentId WHERE (r.RouteId<>e.RouteId OR r.RunDate<e.ValidFrom OR (e.ValidTo IS NOT NULL AND r.RunDate>e.ValidTo)) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52102,''''RideRoute invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER transport.TR_RouteRun_CoverageIntegrity ON transport.RouteRun AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM transport.StudentRide x WITH(UPDLOCK,HOLDLOCK) JOIN transport.RouteRun r WITH(UPDLOCK,HOLDLOCK) ON r.RouteRunId=x.RouteRunId JOIN transport.TransportEnrollment e WITH(UPDLOCK,HOLDLOCK) ON e.TransportEnrollmentId=x.TransportEnrollmentId WHERE (r.RouteId<>e.RouteId OR r.RunDate<e.ValidFrom OR (e.ValidTo IS NOT NULL AND r.RunDate>e.ValidTo)) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52102,''''RideRoute invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER transport.TR_TransportEnrollment_CoverageIntegrity ON transport.TransportEnrollment AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM transport.StudentRide x WITH(UPDLOCK,HOLDLOCK) JOIN transport.RouteRun r WITH(UPDLOCK,HOLDLOCK) ON r.RouteRunId=x.RouteRunId JOIN transport.TransportEnrollment e WITH(UPDLOCK,HOLDLOCK) ON e.TransportEnrollmentId=x.TransportEnrollmentId WHERE (r.RouteId<>e.RouteId OR r.RunDate<e.ValidFrom OR (e.ValidTo IS NOT NULL AND r.RunDate>e.ValidTo)) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52102,''''RideRoute invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER operations.TR_BehaviorEntry_CoverageIntegrity ON operations.BehaviorEntry AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM operations.BehaviorEntry x WITH(UPDLOCK,HOLDLOCK) JOIN operations.BehaviorEntry r WITH(UPDLOCK,HOLDLOCK) ON r.BehaviorEntryId=x.ReversesBehaviorEntryId WHERE (r.StudentId<>x.StudentId OR r.Points<>-x.Points OR r.BehaviorCategoryId<>x.BehaviorCategoryId OR r.ReversesBehaviorEntryId IS NOT NULL) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52103,''''BehaviorReversal invariant violated.'''',1;
END;'');

';
 EXEC sys.sp_executesql N'
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;

EXEC(N''CREATE OR ALTER TRIGGER academic.TR_TimetableLesson_FinalIntegrity ON academic.TimetableLesson AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM academic.TimetableLesson x WITH(UPDLOCK,HOLDLOCK) JOIN academic.TimetableLesson y WITH(UPDLOCK,HOLDLOCK) ON y.SchoolId=x.SchoolId AND y.SchoolYearId=x.SchoolYearId AND y.TermId=x.TermId AND y.DayOfWeek=x.DayOfWeek AND y.TimetableLessonId<>x.TimetableLessonId JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=x.TeachingAssignmentId JOIN academic.TeachingAssignment b WITH(UPDLOCK,HOLDLOCK) ON b.TeachingAssignmentId=y.TeachingAssignmentId JOIN academic.PeriodDefinition p WITH(UPDLOCK,HOLDLOCK) ON p.PeriodId=x.PeriodId JOIN academic.PeriodDefinition q WITH(UPDLOCK,HOLDLOCK) ON q.PeriodId=y.PeriodId WHERE (x.Status=''''active'''' AND y.Status=''''active'''' AND x.EffectiveFrom<=COALESCE(y.EffectiveTo,CONVERT(date,''''99991231'''')) AND y.EffectiveFrom<=COALESCE(x.EffectiveTo,CONVERT(date,''''99991231'''')) AND p.StartTime<q.EndTime AND q.StartTime<p.EndTime AND (a.EmployeeId=b.EmployeeId OR a.ClassSectionId=b.ClassSectionId OR (x.RoomId IS NOT NULL AND x.RoomId=y.RoomId))) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52200,''''TimetableConflict invariant violated.'''',1;
IF EXISTS(SELECT 1 FROM attendance.CoverAssignment x WITH(UPDLOCK,HOLDLOCK) JOIN attendance.LeaveRequest r WITH(UPDLOCK,HOLDLOCK) ON r.LeaveRequestId=x.LeaveRequestId JOIN academic.TimetableLesson t WITH(UPDLOCK,HOLDLOCK) ON t.TimetableLessonId=x.TimetableLessonId JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=t.TeachingAssignmentId WHERE (x.Status=''''active'''' AND (r.Status<>''''approved'''' OR r.EmployeeId<>a.EmployeeId OR x.SubstituteEmployeeId=a.EmployeeId OR x.CoverDate<r.StartDate OR x.CoverDate>r.EndDate OR x.CoverDate<t.EffectiveFrom OR x.CoverDate>COALESCE(t.EffectiveTo,CONVERT(date,''''99991231'''')) OR ((DATEDIFF(day,CONVERT(date,''''19000101''''),x.CoverDate)%7+7)%7+1)<>t.DayOfWeek)) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52201,''''CoverScope invariant violated.'''',1;
IF EXISTS(SELECT 1 FROM attendance.CoverAssignment x WITH(UPDLOCK,HOLDLOCK) JOIN academic.TimetableLesson t WITH(UPDLOCK,HOLDLOCK) ON t.TimetableLessonId=x.TimetableLessonId JOIN academic.PeriodDefinition p WITH(UPDLOCK,HOLDLOCK) ON p.PeriodId=t.PeriodId JOIN academic.TimetableLesson y WITH(UPDLOCK,HOLDLOCK) ON y.SchoolId=x.SchoolId AND y.DayOfWeek=t.DayOfWeek JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=y.TeachingAssignmentId JOIN academic.PeriodDefinition q WITH(UPDLOCK,HOLDLOCK) ON q.PeriodId=y.PeriodId WHERE (x.Status=''''active'''' AND y.Status=''''active'''' AND a.EmployeeId=x.SubstituteEmployeeId AND x.CoverDate BETWEEN y.EffectiveFrom AND COALESCE(y.EffectiveTo,CONVERT(date,''''99991231'''')) AND p.StartTime<q.EndTime AND q.StartTime<p.EndTime) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52202,''''CoverBusy invariant violated.'''',1;
IF EXISTS(SELECT 1 FROM attendance.CoverAssignment x WITH(UPDLOCK,HOLDLOCK) JOIN attendance.CoverAssignment y WITH(UPDLOCK,HOLDLOCK) ON y.SchoolId=x.SchoolId AND y.SubstituteEmployeeId=x.SubstituteEmployeeId AND y.CoverDate=x.CoverDate AND y.CoverAssignmentId<>x.CoverAssignmentId JOIN academic.TimetableLesson a WITH(UPDLOCK,HOLDLOCK) ON a.TimetableLessonId=x.TimetableLessonId JOIN academic.TimetableLesson b WITH(UPDLOCK,HOLDLOCK) ON b.TimetableLessonId=y.TimetableLessonId JOIN academic.PeriodDefinition p WITH(UPDLOCK,HOLDLOCK) ON p.PeriodId=a.PeriodId JOIN academic.PeriodDefinition q WITH(UPDLOCK,HOLDLOCK) ON q.PeriodId=b.PeriodId WHERE (x.Status=''''active'''' AND y.Status=''''active'''' AND p.StartTime<q.EndTime AND q.StartTime<p.EndTime) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52204,''''CoverDuplicate invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER academic.TR_TeachingAssignment_FinalIntegrity ON academic.TeachingAssignment AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM academic.TimetableLesson x WITH(UPDLOCK,HOLDLOCK) JOIN academic.TimetableLesson y WITH(UPDLOCK,HOLDLOCK) ON y.SchoolId=x.SchoolId AND y.SchoolYearId=x.SchoolYearId AND y.TermId=x.TermId AND y.DayOfWeek=x.DayOfWeek AND y.TimetableLessonId<>x.TimetableLessonId JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=x.TeachingAssignmentId JOIN academic.TeachingAssignment b WITH(UPDLOCK,HOLDLOCK) ON b.TeachingAssignmentId=y.TeachingAssignmentId JOIN academic.PeriodDefinition p WITH(UPDLOCK,HOLDLOCK) ON p.PeriodId=x.PeriodId JOIN academic.PeriodDefinition q WITH(UPDLOCK,HOLDLOCK) ON q.PeriodId=y.PeriodId WHERE (x.Status=''''active'''' AND y.Status=''''active'''' AND x.EffectiveFrom<=COALESCE(y.EffectiveTo,CONVERT(date,''''99991231'''')) AND y.EffectiveFrom<=COALESCE(x.EffectiveTo,CONVERT(date,''''99991231'''')) AND p.StartTime<q.EndTime AND q.StartTime<p.EndTime AND (a.EmployeeId=b.EmployeeId OR a.ClassSectionId=b.ClassSectionId OR (x.RoomId IS NOT NULL AND x.RoomId=y.RoomId))) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52200,''''TimetableConflict invariant violated.'''',1;
IF EXISTS(SELECT 1 FROM attendance.CoverAssignment x WITH(UPDLOCK,HOLDLOCK) JOIN attendance.LeaveRequest r WITH(UPDLOCK,HOLDLOCK) ON r.LeaveRequestId=x.LeaveRequestId JOIN academic.TimetableLesson t WITH(UPDLOCK,HOLDLOCK) ON t.TimetableLessonId=x.TimetableLessonId JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=t.TeachingAssignmentId WHERE (x.Status=''''active'''' AND (r.Status<>''''approved'''' OR r.EmployeeId<>a.EmployeeId OR x.SubstituteEmployeeId=a.EmployeeId OR x.CoverDate<r.StartDate OR x.CoverDate>r.EndDate OR x.CoverDate<t.EffectiveFrom OR x.CoverDate>COALESCE(t.EffectiveTo,CONVERT(date,''''99991231'''')) OR ((DATEDIFF(day,CONVERT(date,''''19000101''''),x.CoverDate)%7+7)%7+1)<>t.DayOfWeek)) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52201,''''CoverScope invariant violated.'''',1;
IF EXISTS(SELECT 1 FROM attendance.CoverAssignment x WITH(UPDLOCK,HOLDLOCK) JOIN academic.TimetableLesson t WITH(UPDLOCK,HOLDLOCK) ON t.TimetableLessonId=x.TimetableLessonId JOIN academic.PeriodDefinition p WITH(UPDLOCK,HOLDLOCK) ON p.PeriodId=t.PeriodId JOIN academic.TimetableLesson y WITH(UPDLOCK,HOLDLOCK) ON y.SchoolId=x.SchoolId AND y.DayOfWeek=t.DayOfWeek JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=y.TeachingAssignmentId JOIN academic.PeriodDefinition q WITH(UPDLOCK,HOLDLOCK) ON q.PeriodId=y.PeriodId WHERE (x.Status=''''active'''' AND y.Status=''''active'''' AND a.EmployeeId=x.SubstituteEmployeeId AND x.CoverDate BETWEEN y.EffectiveFrom AND COALESCE(y.EffectiveTo,CONVERT(date,''''99991231'''')) AND p.StartTime<q.EndTime AND q.StartTime<p.EndTime) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52202,''''CoverBusy invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER academic.TR_PeriodDefinition_FinalIntegrity ON academic.PeriodDefinition AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM academic.TimetableLesson x WITH(UPDLOCK,HOLDLOCK) JOIN academic.TimetableLesson y WITH(UPDLOCK,HOLDLOCK) ON y.SchoolId=x.SchoolId AND y.SchoolYearId=x.SchoolYearId AND y.TermId=x.TermId AND y.DayOfWeek=x.DayOfWeek AND y.TimetableLessonId<>x.TimetableLessonId JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=x.TeachingAssignmentId JOIN academic.TeachingAssignment b WITH(UPDLOCK,HOLDLOCK) ON b.TeachingAssignmentId=y.TeachingAssignmentId JOIN academic.PeriodDefinition p WITH(UPDLOCK,HOLDLOCK) ON p.PeriodId=x.PeriodId JOIN academic.PeriodDefinition q WITH(UPDLOCK,HOLDLOCK) ON q.PeriodId=y.PeriodId WHERE (x.Status=''''active'''' AND y.Status=''''active'''' AND x.EffectiveFrom<=COALESCE(y.EffectiveTo,CONVERT(date,''''99991231'''')) AND y.EffectiveFrom<=COALESCE(x.EffectiveTo,CONVERT(date,''''99991231'''')) AND p.StartTime<q.EndTime AND q.StartTime<p.EndTime AND (a.EmployeeId=b.EmployeeId OR a.ClassSectionId=b.ClassSectionId OR (x.RoomId IS NOT NULL AND x.RoomId=y.RoomId))) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52200,''''TimetableConflict invariant violated.'''',1;
IF EXISTS(SELECT 1 FROM attendance.CoverAssignment x WITH(UPDLOCK,HOLDLOCK) JOIN academic.TimetableLesson t WITH(UPDLOCK,HOLDLOCK) ON t.TimetableLessonId=x.TimetableLessonId JOIN academic.PeriodDefinition p WITH(UPDLOCK,HOLDLOCK) ON p.PeriodId=t.PeriodId JOIN academic.TimetableLesson y WITH(UPDLOCK,HOLDLOCK) ON y.SchoolId=x.SchoolId AND y.DayOfWeek=t.DayOfWeek JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=y.TeachingAssignmentId JOIN academic.PeriodDefinition q WITH(UPDLOCK,HOLDLOCK) ON q.PeriodId=y.PeriodId WHERE (x.Status=''''active'''' AND y.Status=''''active'''' AND a.EmployeeId=x.SubstituteEmployeeId AND x.CoverDate BETWEEN y.EffectiveFrom AND COALESCE(y.EffectiveTo,CONVERT(date,''''99991231'''')) AND p.StartTime<q.EndTime AND q.StartTime<p.EndTime) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52202,''''CoverBusy invariant violated.'''',1;
IF EXISTS(SELECT 1 FROM attendance.CoverAssignment x WITH(UPDLOCK,HOLDLOCK) JOIN attendance.CoverAssignment y WITH(UPDLOCK,HOLDLOCK) ON y.SchoolId=x.SchoolId AND y.SubstituteEmployeeId=x.SubstituteEmployeeId AND y.CoverDate=x.CoverDate AND y.CoverAssignmentId<>x.CoverAssignmentId JOIN academic.TimetableLesson a WITH(UPDLOCK,HOLDLOCK) ON a.TimetableLessonId=x.TimetableLessonId JOIN academic.TimetableLesson b WITH(UPDLOCK,HOLDLOCK) ON b.TimetableLessonId=y.TimetableLessonId JOIN academic.PeriodDefinition p WITH(UPDLOCK,HOLDLOCK) ON p.PeriodId=a.PeriodId JOIN academic.PeriodDefinition q WITH(UPDLOCK,HOLDLOCK) ON q.PeriodId=b.PeriodId WHERE (x.Status=''''active'''' AND y.Status=''''active'''' AND p.StartTime<q.EndTime AND q.StartTime<p.EndTime) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52204,''''CoverDuplicate invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER attendance.TR_CoverAssignment_FinalIntegrity ON attendance.CoverAssignment AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM attendance.CoverAssignment x WITH(UPDLOCK,HOLDLOCK) JOIN attendance.LeaveRequest r WITH(UPDLOCK,HOLDLOCK) ON r.LeaveRequestId=x.LeaveRequestId JOIN academic.TimetableLesson t WITH(UPDLOCK,HOLDLOCK) ON t.TimetableLessonId=x.TimetableLessonId JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=t.TeachingAssignmentId WHERE (x.Status=''''active'''' AND (r.Status<>''''approved'''' OR r.EmployeeId<>a.EmployeeId OR x.SubstituteEmployeeId=a.EmployeeId OR x.CoverDate<r.StartDate OR x.CoverDate>r.EndDate OR x.CoverDate<t.EffectiveFrom OR x.CoverDate>COALESCE(t.EffectiveTo,CONVERT(date,''''99991231'''')) OR ((DATEDIFF(day,CONVERT(date,''''19000101''''),x.CoverDate)%7+7)%7+1)<>t.DayOfWeek)) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52201,''''CoverScope invariant violated.'''',1;
IF EXISTS(SELECT 1 FROM attendance.CoverAssignment x WITH(UPDLOCK,HOLDLOCK) JOIN academic.TimetableLesson t WITH(UPDLOCK,HOLDLOCK) ON t.TimetableLessonId=x.TimetableLessonId JOIN academic.PeriodDefinition p WITH(UPDLOCK,HOLDLOCK) ON p.PeriodId=t.PeriodId JOIN academic.TimetableLesson y WITH(UPDLOCK,HOLDLOCK) ON y.SchoolId=x.SchoolId AND y.DayOfWeek=t.DayOfWeek JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=y.TeachingAssignmentId JOIN academic.PeriodDefinition q WITH(UPDLOCK,HOLDLOCK) ON q.PeriodId=y.PeriodId WHERE (x.Status=''''active'''' AND y.Status=''''active'''' AND a.EmployeeId=x.SubstituteEmployeeId AND x.CoverDate BETWEEN y.EffectiveFrom AND COALESCE(y.EffectiveTo,CONVERT(date,''''99991231'''')) AND p.StartTime<q.EndTime AND q.StartTime<p.EndTime) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52202,''''CoverBusy invariant violated.'''',1;
IF EXISTS(SELECT 1 FROM attendance.CoverAssignment x WITH(UPDLOCK,HOLDLOCK) JOIN attendance.LeaveRequest r WITH(UPDLOCK,HOLDLOCK) ON r.SchoolId=x.SchoolId AND r.EmployeeId=x.SubstituteEmployeeId WHERE (x.Status=''''active'''' AND r.Status=''''approved'''' AND x.CoverDate BETWEEN r.StartDate AND r.EndDate) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52203,''''CoverLeave invariant violated.'''',1;
IF EXISTS(SELECT 1 FROM attendance.CoverAssignment x WITH(UPDLOCK,HOLDLOCK) JOIN attendance.CoverAssignment y WITH(UPDLOCK,HOLDLOCK) ON y.SchoolId=x.SchoolId AND y.SubstituteEmployeeId=x.SubstituteEmployeeId AND y.CoverDate=x.CoverDate AND y.CoverAssignmentId<>x.CoverAssignmentId JOIN academic.TimetableLesson a WITH(UPDLOCK,HOLDLOCK) ON a.TimetableLessonId=x.TimetableLessonId JOIN academic.TimetableLesson b WITH(UPDLOCK,HOLDLOCK) ON b.TimetableLessonId=y.TimetableLessonId JOIN academic.PeriodDefinition p WITH(UPDLOCK,HOLDLOCK) ON p.PeriodId=a.PeriodId JOIN academic.PeriodDefinition q WITH(UPDLOCK,HOLDLOCK) ON q.PeriodId=b.PeriodId WHERE (x.Status=''''active'''' AND y.Status=''''active'''' AND p.StartTime<q.EndTime AND q.StartTime<p.EndTime) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52204,''''CoverDuplicate invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER attendance.TR_LeaveRequest_FinalIntegrity ON attendance.LeaveRequest AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM attendance.CoverAssignment x WITH(UPDLOCK,HOLDLOCK) JOIN attendance.LeaveRequest r WITH(UPDLOCK,HOLDLOCK) ON r.LeaveRequestId=x.LeaveRequestId JOIN academic.TimetableLesson t WITH(UPDLOCK,HOLDLOCK) ON t.TimetableLessonId=x.TimetableLessonId JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=t.TeachingAssignmentId WHERE (x.Status=''''active'''' AND (r.Status<>''''approved'''' OR r.EmployeeId<>a.EmployeeId OR x.SubstituteEmployeeId=a.EmployeeId OR x.CoverDate<r.StartDate OR x.CoverDate>r.EndDate OR x.CoverDate<t.EffectiveFrom OR x.CoverDate>COALESCE(t.EffectiveTo,CONVERT(date,''''99991231'''')) OR ((DATEDIFF(day,CONVERT(date,''''19000101''''),x.CoverDate)%7+7)%7+1)<>t.DayOfWeek)) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52201,''''CoverScope invariant violated.'''',1;
IF EXISTS(SELECT 1 FROM attendance.CoverAssignment x WITH(UPDLOCK,HOLDLOCK) JOIN attendance.LeaveRequest r WITH(UPDLOCK,HOLDLOCK) ON r.SchoolId=x.SchoolId AND r.EmployeeId=x.SubstituteEmployeeId WHERE (x.Status=''''active'''' AND r.Status=''''approved'''' AND x.CoverDate BETWEEN r.StartDate AND r.EndDate) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52203,''''CoverLeave invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER hr.TR_PayrollRun_FinalIntegrity ON hr.PayrollRun AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM hr.PayrollRunLine x WITH(UPDLOCK,HOLDLOCK) JOIN hr.PayrollRun r WITH(UPDLOCK,HOLDLOCK) ON r.PayrollRunId=x.PayrollRunId WHERE (x.CurrencyCode<>r.CurrencyCode) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52205,''''PayrollCurrency invariant violated.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER hr.TR_PayrollRunLine_FinalIntegrity ON hr.PayrollRunLine AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; DECLARE @schools table(SchoolId uniqueidentifier PRIMARY KEY); INSERT @schools SELECT SchoolId FROM inserted UNION SELECT SchoolId FROM deleted;
IF EXISTS(SELECT 1 FROM hr.PayrollRunLine x WITH(UPDLOCK,HOLDLOCK) JOIN hr.PayrollRun r WITH(UPDLOCK,HOLDLOCK) ON r.PayrollRunId=x.PayrollRunId WHERE (x.CurrencyCode<>r.CurrencyCode) AND x.SchoolId IN(SELECT SchoolId FROM @schools)) THROW 52205,''''PayrollCurrency invariant violated.'''',1;
END;'');

';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(20,N''020_preserve_domain_guards.sql'',0x2660b795482444d186daf16f1afa8f05c4dd0c91477399f0800a597c793d259a,''executed'');';
 -- BEGIN 021_submission_workflow_contracts.sql
 EXEC sys.sp_executesql N'SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
';
 EXEC sys.sp_executesql N'

ALTER TABLE learning.SupervisoryVisit ADD SupersedesVisitId uniqueidentifier NULL;
';
 EXEC sys.sp_executesql N'
ALTER TABLE learning.SupervisoryVisit ADD CONSTRAINT FK_Visit_Supersedes FOREIGN KEY(SchoolId,SupersedesVisitId) REFERENCES learning.SupervisoryVisit(SchoolId,SupervisoryVisitId);
CREATE UNIQUE INDEX UX_Visit_Supersedes ON learning.SupervisoryVisit(SchoolId,SupersedesVisitId) WHERE SupersedesVisitId IS NOT NULL;

';
 EXEC sys.sp_executesql N'
CREATE OR ALTER TRIGGER assessment.TR_ExamQuestion_History ON assessment.ExamQuestion AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM (SELECT ExamId FROM inserted UNION SELECT ExamId FROM deleted) x JOIN assessment.Exam e WITH(UPDLOCK,HOLDLOCK) ON e.ExamId=x.ExamId WHERE e.Status<>''draft'') THROW 52400,''Released exam structure is immutable; create a new exam.'',1;
END;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER TRIGGER assessment.TR_Exam_History ON assessment.Exam AFTER UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM deleted d LEFT JOIN inserted i ON i.ExamId=d.ExamId WHERE d.Status<>''draft'' AND (i.ExamId IS NULL OR i.Status=''draft'' OR i.TeachingAssignmentId<>d.TeachingAssignmentId OR i.Title<>d.Title OR i.OpensAtUtc<>d.OpensAtUtc OR i.ClosesAtUtc<>d.ClosesAtUtc OR i.DurationMinutes<>d.DurationMinutes OR i.MaximumAttempts<>d.MaximumAttempts OR i.SchoolId<>d.SchoolId)) THROW 52401,''Released exam identity and configuration are immutable.'',1;
END;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER TRIGGER learning.TR_CompletedVisit_History ON learning.SupervisoryVisit AFTER UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM deleted WHERE Status=''completed'') THROW 52402,''Completed visits are historical; use CreateVisitCorrection.'',1;
END;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER PROCEDURE learning.CreateVisitCorrection @SchoolId uniqueidentifier,@VisitId uniqueidentifier,@ActorUserId uniqueidentifier,@Reason nvarchar(2000)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @new uniqueidentifier=NEWID();
 BEGIN TRY
  BEGIN TRANSACTION;
  IF security.HasSchoolPermission(@ActorUserId,@SchoolId,''grades.review'')=0 THROW 52403,''Supervisor permission required.'',1;
  IF NULLIF(LTRIM(RTRIM(@Reason)),N'''') IS NULL THROW 52404,''Correction reason required.'',1;
  INSERT learning.SupervisoryVisit(SupervisoryVisitId,SchoolId,RubricId,EmployeeId,SupervisorUserId,ScheduledAtUtc,Status,Recommendations,SupersedesVisitId)
  SELECT @new,SchoolId,RubricId,EmployeeId,@ActorUserId,SYSUTCDATETIME(),''scheduled'',@Reason,SupervisoryVisitId FROM learning.SupervisoryVisit WITH(UPDLOCK,HOLDLOCK) WHERE SchoolId=@SchoolId AND SupervisoryVisitId=@VisitId AND Status=''completed'';
  IF @@ROWCOUNT<>1 THROW 52405,''Completed visit not found.'',1;
  INSERT audit.AuditEvent(OrganizationId,SchoolId,ActorUserId,ActionCode,EntityType,EntityId,Outcome) SELECT OrganizationId,@SchoolId,@ActorUserId,''visit.correction.created'',''learning.SupervisoryVisit'',CONVERT(nvarchar(36),@new),''success'' FROM core.School WHERE SchoolId=@SchoolId;
  COMMIT; SELECT @new SupervisoryVisitId;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER PROCEDURE hr.ApprovePayroll @SchoolId uniqueidentifier,@PayrollRunId uniqueidentifier,@ActorUserId uniqueidentifier
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY
 BEGIN TRANSACTION;
 IF security.HasSchoolPermission(@ActorUserId,@SchoolId,''payroll.manage'')=0 THROW 52406,''Payroll permission required.'',1;
 IF NOT EXISTS(SELECT 1 FROM hr.PayrollRun WITH(UPDLOCK,HOLDLOCK) WHERE SchoolId=@SchoolId AND PayrollRunId=@PayrollRunId AND Status=''submitted'') THROW 52407,''Submitted payroll required.'',1;
 IF NOT EXISTS(SELECT 1 FROM hr.PayrollRunLine WITH(UPDLOCK,HOLDLOCK) WHERE SchoolId=@SchoolId AND PayrollRunId=@PayrollRunId) THROW 52408,''Payroll has no lines.'',1;
 UPDATE hr.PayrollRun SET Status=''approved'',ApprovedByUserId=@ActorUserId,ApprovedAtUtc=SYSUTCDATETIME() WHERE PayrollRunId=@PayrollRunId;
 INSERT audit.AuditEvent(OrganizationId,SchoolId,ActorUserId,ActionCode,EntityType,EntityId,Outcome) SELECT OrganizationId,@SchoolId,@ActorUserId,''payroll.approved'',''hr.PayrollRun'',CONVERT(nvarchar(36),@PayrollRunId),''success'' FROM core.School WHERE SchoolId=@SchoolId;
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER PROCEDURE hr.MarkPayrollPaid @SchoolId uniqueidentifier,@PayrollRunId uniqueidentifier,@ActorUserId uniqueidentifier
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY
 BEGIN TRANSACTION;
 IF security.HasSchoolPermission(@ActorUserId,@SchoolId,''payroll.manage'')=0 THROW 52406,''Payroll permission required.'',1;
 UPDATE hr.PayrollRun WITH(UPDLOCK,HOLDLOCK) SET Status=''paid'' WHERE SchoolId=@SchoolId AND PayrollRunId=@PayrollRunId AND Status=''approved'' AND ApprovedByUserId IS NOT NULL AND ApprovedAtUtc IS NOT NULL;
 IF @@ROWCOUNT<>1 THROW 52409,''Approved payroll with approval identity required.'',1;
 INSERT audit.AuditEvent(OrganizationId,SchoolId,ActorUserId,ActionCode,EntityType,EntityId,Outcome) SELECT OrganizationId,@SchoolId,@ActorUserId,''payroll.paid'',''hr.PayrollRun'',CONVERT(nvarchar(36),@PayrollRunId),''success'' FROM core.School WHERE SchoolId=@SchoolId;
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER PROCEDURE core.AssertOrganizationLicense @OrganizationId uniqueidentifier
AS
BEGIN
 SET NOCOUNT ON;
 -- No configured license means evaluation mode. Configured organizations fail closed.
 IF EXISTS(SELECT 1 FROM core.OrganizationLicense WHERE OrganizationId=@OrganizationId)
 AND NOT EXISTS(SELECT 1 FROM core.OrganizationLicense WHERE OrganizationId=@OrganizationId AND Status=''active'' AND CONVERT(date,SYSUTCDATETIME()) BETWEEN ValidFrom AND ValidTo)
 THROW 52410,''Organization license is expired, suspended or inactive.'',1;
END;
';
 EXEC sys.sp_executesql N'
DENY INSERT,UPDATE,DELETE ON hr.PayrollRun TO awn_backend;
DENY INSERT,UPDATE,DELETE ON learning.SupervisoryVisit TO awn_backend;
GRANT EXECUTE ON hr.ApprovePayroll TO awn_backend;
GRANT EXECUTE ON hr.MarkPayrollPaid TO awn_backend;
GRANT EXECUTE ON learning.CreateVisitCorrection TO awn_backend;
GRANT EXECUTE ON core.AssertOrganizationLicense TO awn_backend;
';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(21,N''021_submission_workflow_contracts.sql'',0x76df2d3836cc53263a4d18724e698f143a4faa5c97c8d972c960887dd22470a1,''executed'');';
 -- BEGIN 022_require_gradebook_revision.sql
 EXEC sys.sp_executesql N'SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER PROCEDURE assessment.TransitionGradebook
 @SchoolId uniqueidentifier,@GradebookId uniqueidentifier,@ActorUserId uniqueidentifier,@ExpectedRevision int,@ToStatus varchar(20),@Note nvarchar(2000)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @from varchar(20),@revision int,@permission varchar(120);
 BEGIN TRY
  BEGIN TRANSACTION;
  SELECT @from=Status,@revision=Revision FROM assessment.Gradebook WITH(UPDLOCK,HOLDLOCK) WHERE SchoolId=@SchoolId AND GradebookId=@GradebookId;
  IF @ExpectedRevision IS NULL OR @ExpectedRevision<=0 OR @from IS NULL OR @revision<>@ExpectedRevision THROW 51602,''Gradebook not found or stale revision.'',1;
  SET @permission=CASE WHEN @ToStatus=''submitted'' THEN ''grades.enter'' WHEN @ToStatus IN (''reviewed'',''returned'') THEN ''grades.review'' WHEN @ToStatus=''approved'' THEN ''grades.publish'' END;
  IF @permission IS NULL OR security.HasSchoolPermission(@ActorUserId,@SchoolId,@permission)=0 THROW 51603,''Permission denied.'',1;
  IF NOT ((@from IN (''draft'',''returned'') AND @ToStatus=''submitted'') OR (@from=''submitted'' AND @ToStatus IN (''reviewed'',''returned'')) OR (@from=''reviewed'' AND @ToStatus IN (''approved'',''returned''))) THROW 51604,''Invalid gradebook transition.'',1;
  IF NOT EXISTS(SELECT 1 FROM assessment.Gradebook b JOIN assessment.GradingPolicy p ON p.GradingPolicyId=b.GradingPolicyId WHERE b.GradebookId=@GradebookId AND p.Status=''approved'') THROW 51605,''An approved policy is required.'',1;
  UPDATE assessment.Gradebook SET Status=@ToStatus,Revision=Revision+1 WHERE GradebookId=@GradebookId;
  INSERT assessment.GradebookWorkflowEvent(SchoolId,GradebookId,ActorUserId,FromStatus,ToStatus,Note,Revision) VALUES(@SchoolId,@GradebookId,@ActorUserId,@from,@ToStatus,@Note,@revision+1);
  COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER PROCEDURE assessment.PublishGradebook
 @SchoolId uniqueidentifier,@GradebookId uniqueidentifier,@ActorUserId uniqueidentifier,@ExpectedRevision int
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @status varchar(20),@revision int,@policy uniqueidentifier,@class uniqueidentifier,@mode varchar(20),@round varchar(20),@version int,@pub uniqueidentifier=NEWID(),@payload nvarchar(max);
 BEGIN TRY
  BEGIN TRANSACTION;
  SELECT @status=b.Status,@revision=b.Revision,@policy=b.GradingPolicyId,@class=a.ClassSectionId,@mode=p.AssessmentMode,@round=p.RoundingRule FROM assessment.Gradebook b WITH(UPDLOCK,HOLDLOCK) JOIN academic.TeachingAssignment a WITH(UPDLOCK,HOLDLOCK) ON a.TeachingAssignmentId=b.TeachingAssignmentId JOIN assessment.GradingPolicy p WITH(UPDLOCK,HOLDLOCK) ON p.GradingPolicyId=b.GradingPolicyId WHERE b.SchoolId=@SchoolId AND b.GradebookId=@GradebookId AND p.Status=''approved'';
  IF @ExpectedRevision IS NULL OR @ExpectedRevision<=0 OR @status IS NULL OR @status<>''approved'' OR @revision<>@ExpectedRevision THROW 51606,''Approved gradebook with current revision required.'',1;
  IF security.HasSchoolPermission(@ActorUserId,@SchoolId,''grades.publish'')=0 THROW 51603,''Permission denied.'',1;
  -- Numeric totals are calculated by SQL; missing required results cannot silently become zero.
  IF NOT EXISTS(SELECT 1 FROM assessment.GradingComponent WHERE GradingPolicyId=@policy) THROW 51607,''Policy has no components.'',1;
  IF EXISTS(SELECT 1 FROM people.StudentEnrollment e WITH(UPDLOCK,HOLDLOCK) CROSS JOIN assessment.GradingComponent c WITH(UPDLOCK,HOLDLOCK) LEFT JOIN assessment.GradeItem g WITH(UPDLOCK,HOLDLOCK) ON g.EnrollmentId=e.EnrollmentId AND g.GradingComponentId=c.GradingComponentId AND g.GradebookId=@GradebookId WHERE e.SchoolId=@SchoolId AND e.ClassSectionId=@class AND e.Status=''active'' AND c.GradingPolicyId=@policy AND c.IsRequired=1 AND (g.GradeItemId IS NULL OR (@mode IN (''weighted'',''hybrid'') AND c.MaximumScore IS NOT NULL AND g.Score IS NULL) OR (@mode=''descriptive'' AND g.DescriptiveLevel IS NULL))) THROW 51608,''Required student results are missing.'',1;
  IF @mode IN (''weighted'',''hybrid'') AND EXISTS(SELECT 1 FROM assessment.GradingComponent WHERE GradingPolicyId=@policy GROUP BY GradingPolicyId HAVING SUM(CASE WHEN MaximumScore IS NOT NULL THEN COALESCE(WeightPercent,0) ELSE 0 END)<>100 OR SUM(CASE WHEN MaximumScore IS NOT NULL AND WeightPercent IS NULL THEN 1 ELSE 0 END)>0) THROW 51613,''Numeric components must have weights totaling 100.'',1;
  DECLARE @results table(EnrollmentId uniqueidentifier PRIMARY KEY,Score decimal(9,4),MaximumScore decimal(9,4),DescriptiveResult nvarchar(500),DetailsJson nvarchar(max));
  INSERT @results
  SELECT e.EnrollmentId,CASE WHEN @mode=''descriptive'' THEN NULL ELSE SUM(COALESCE(g.Score/NULLIF(c.MaximumScore,0)*c.WeightPercent,0)) END,CASE WHEN @mode=''descriptive'' THEN NULL ELSE 100 END,
   CASE WHEN @mode IN (''descriptive'',''hybrid'') THEN N''See component results'' ELSE NULL END,
   (SELECT c2.Code,c2.Name,c2.MaximumScore,c2.WeightPercent,g2.Score,g2.DescriptiveLevel,g2.Feedback FROM assessment.GradingComponent c2 LEFT JOIN assessment.GradeItem g2 ON g2.GradingComponentId=c2.GradingComponentId AND g2.EnrollmentId=e.EnrollmentId AND g2.GradebookId=@GradebookId WHERE c2.GradingPolicyId=@policy ORDER BY c2.SortOrder,c2.Code FOR JSON PATH)
  FROM people.StudentEnrollment e WITH(UPDLOCK,HOLDLOCK) CROSS JOIN assessment.GradingComponent c WITH(UPDLOCK,HOLDLOCK) LEFT JOIN assessment.GradeItem g WITH(UPDLOCK,HOLDLOCK) ON g.EnrollmentId=e.EnrollmentId AND g.GradingComponentId=c.GradingComponentId AND g.GradebookId=@GradebookId
  WHERE e.SchoolId=@SchoolId AND e.ClassSectionId=@class AND e.Status=''active'' AND c.GradingPolicyId=@policy GROUP BY e.EnrollmentId;
  IF NOT EXISTS(SELECT 1 FROM @results) THROW 51609,''No active student results to publish.'',1;
  UPDATE @results SET Score=CASE @round WHEN ''nearest'' THEN ROUND(Score,0) WHEN ''floor'' THEN FLOOR(Score) WHEN ''ceiling'' THEN CEILING(Score) ELSE Score END;
  SELECT @payload=(SELECT EnrollmentId,Score,MaximumScore,DescriptiveResult,DetailsJson FROM @results ORDER BY EnrollmentId FOR JSON PATH,INCLUDE_NULL_VALUES);
  SELECT @version=COALESCE(MAX(VersionNo),0)+1 FROM assessment.GradePublication WITH(UPDLOCK,HOLDLOCK) WHERE SchoolId=@SchoolId AND GradebookId=@GradebookId;
  INSERT assessment.GradePublication(GradePublicationId,SchoolId,GradebookId,VersionNo,SnapshotHash,PublishedByUserId) VALUES(@pub,@SchoolId,@GradebookId,@version,HASHBYTES(''SHA2_256'',@payload),@ActorUserId);
  INSERT assessment.PublishedGrade(SchoolId,GradePublicationId,EnrollmentId,Score,MaximumScore,DescriptiveResult,DetailsJson) SELECT @SchoolId,@pub,EnrollmentId,Score,MaximumScore,DescriptiveResult,DetailsJson FROM @results;
  UPDATE assessment.GradePublication SET SealedAtUtc=SYSUTCDATETIME() WHERE GradePublicationId=@pub;
  UPDATE assessment.Gradebook SET Status=''locked'',LockedAtUtc=SYSUTCDATETIME(),Revision=Revision+1 WHERE GradebookId=@GradebookId;
  INSERT assessment.GradebookWorkflowEvent(SchoolId,GradebookId,ActorUserId,FromStatus,ToStatus,Revision) VALUES(@SchoolId,@GradebookId,@ActorUserId,''approved'',''locked'',@revision+1);
  COMMIT;
  SELECT @pub AS GradePublicationId,@version AS VersionNo;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(22,N''022_require_gradebook_revision.sql'',0x2a4003a97ba289797ca4b8d77c5d373026f297acdeda90eb70f3eade826b7cbf,''executed'');';
 -- BEGIN 023_school_workflow_foundations.sql
 EXEC sys.sp_executesql N'SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;

INSERT security.Permission(Code,Description)
SELECT v.Code,v.Description FROM(VALUES
 (''files.upload'',N''رفع المرفقات الخاصة''),(''attendance.approve'',N''قفل وإعادة فتح كشوف الحضور''),
 (''plans.read'',N''قراءة الخطط الدراسية''),(''plans.manage'',N''تحرير الخطط الدراسية''),(''plans.review'',N''مراجعة الخطط الدراسية''),
 (''supervision.read'',N''قراءة الزيارات الإشرافية''),(''supervision.manage'',N''إدارة الزيارات ومعاييرها''),(''supervision.assign'',N''إسناد نطاق المشرف التربوي''),(''leave.balances.manage'',N''إدارة أرصدة الإجازات''),(''cover.manage'',N''إدارة حصص التغطية'')
)v(Code,Description) WHERE NOT EXISTS(SELECT 1 FROM security.Permission p WHERE p.Code=v.Code);
INSERT security.RolePermission(RoleId,PermissionId)
SELECT r.RoleId,p.PermissionId FROM(VALUES
 (''admin'',''files.upload''),(''admin'',''attendance.read''),(''admin'',''attendance.record''),(''admin'',''attendance.approve''),(''admin'',''leave.decide''),(''admin'',''leave.balances.manage''),(''admin'',''cover.manage''),(''admin'',''plans.read''),(''admin'',''plans.manage''),(''admin'',''plans.review''),(''admin'',''supervision.read''),(''admin'',''supervision.manage''),(''admin'',''supervision.assign''),(''principal'',''supervision.assign''),(''hr_officer'',''leave.balances.manage''),
 (''principal'',''files.upload''),(''principal'',''attendance.approve''),(''principal'',''cover.manage''),(''principal'',''plans.read''),(''principal'',''plans.review''),(''principal'',''supervision.read''),(''principal'',''supervision.manage''),
 (''supervisor'',''files.upload''),(''supervisor'',''plans.read''),(''supervisor'',''plans.review''),(''supervisor'',''supervision.read''),(''supervisor'',''supervision.manage''),
 (''teacher'',''files.upload''),(''teacher'',''plans.read''),(''teacher'',''plans.manage''),(''teacher'',''supervision.read''),(''student'',''files.upload''),(''parent'',''files.upload'')
)v(RoleCode,PermissionCode) JOIN security.Role r ON r.Code=v.RoleCode JOIN security.Permission p ON p.Code=v.PermissionCode
WHERE NOT EXISTS(SELECT 1 FROM security.RolePermission rp WHERE rp.RoleId=r.RoleId AND rp.PermissionId=p.PermissionId);
ALTER TABLE attendance.AttendanceSession ADD TimetableLessonId uniqueidentifier NULL;
ALTER TABLE attendance.AttendanceSession ADD CONSTRAINT FK_AttendanceSession_Lesson FOREIGN KEY(SchoolId,TimetableLessonId) REFERENCES academic.TimetableLesson(SchoolId,TimetableLessonId);
ALTER TABLE attendance.LeaveRequest ADD StartTimeLocal time(0) NULL,EndTimeLocal time(0) NULL;
';
 EXEC sys.sp_executesql N'
ALTER TABLE attendance.LeaveRequest ADD CONSTRAINT CK_LeaveRequest_LocalTimes CHECK((StartTimeLocal IS NULL AND EndTimeLocal IS NULL) OR(StartTimeLocal IS NOT NULL AND EndTimeLocal IS NOT NULL AND StartDate=EndDate AND StartTimeLocal<EndTimeLocal));
ALTER TABLE learning.SupervisoryVisit ADD RowVersion rowversion NOT NULL;
ALTER TABLE learning.SupervisoryVisit ADD DurationMinutes int NOT NULL CONSTRAINT DF_Visit_Duration DEFAULT (45);
';
 EXEC sys.sp_executesql N'
ALTER TABLE learning.SupervisoryVisit ADD CONSTRAINT CK_Visit_Duration CHECK(DurationMinutes BETWEEN 1 AND 240);
CREATE TABLE learning.PlanProgress(
 SchoolId uniqueidentifier NOT NULL,PlanId uniqueidentifier NOT NULL,
 CompletedUnits int NOT NULL,TotalUnits int NOT NULL,Note nvarchar(1000) NOT NULL,
 RecordedByUserId uniqueidentifier NOT NULL,RecordedAtUtc datetime2(3) NOT NULL DEFAULT SYSUTCDATETIME(),RowVersion rowversion NOT NULL,
 CONSTRAINT PK_PlanProgress PRIMARY KEY(SchoolId,PlanId),
 CONSTRAINT FK_PlanProgress_Plan FOREIGN KEY(SchoolId,PlanId) REFERENCES learning.[Plan](SchoolId,PlanId),
 CONSTRAINT FK_PlanProgress_Actor FOREIGN KEY(RecordedByUserId) REFERENCES security.UserAccount(UserId),
 CONSTRAINT CK_PlanProgress_Units CHECK(CompletedUnits>=0 AND TotalUnits>0 AND CompletedUnits<=TotalUnits));
CREATE TABLE academic.SupervisionScope(
 SupervisionScopeId uniqueidentifier NOT NULL CONSTRAINT DF_SupervisionScope_Id DEFAULT NEWSEQUENTIALID(),
 SchoolId uniqueidentifier NOT NULL,SupervisorUserId uniqueidentifier NOT NULL,EmployeeId uniqueidentifier NULL,SubjectId uniqueidentifier NULL,
 ValidFrom date NOT NULL,ValidTo date NULL,Status varchar(20) NOT NULL DEFAULT ''active'',CreatedByUserId uniqueidentifier NOT NULL,RowVersion rowversion NOT NULL,
 CONSTRAINT PK_SupervisionScope PRIMARY KEY(SupervisionScopeId),
 CONSTRAINT FK_SupervisionScope_School FOREIGN KEY(SchoolId) REFERENCES core.School(SchoolId),
 CONSTRAINT FK_SupervisionScope_User FOREIGN KEY(SupervisorUserId) REFERENCES security.UserAccount(UserId),
 CONSTRAINT FK_SupervisionScope_Employee FOREIGN KEY(SchoolId,EmployeeId) REFERENCES people.EmployeeProfile(SchoolId,EmployeeId),
 CONSTRAINT FK_SupervisionScope_Subject FOREIGN KEY(SchoolId,SubjectId) REFERENCES academic.Subject(SchoolId,SubjectId),
 CONSTRAINT FK_SupervisionScope_Actor FOREIGN KEY(CreatedByUserId) REFERENCES security.UserAccount(UserId),
 CONSTRAINT CK_SupervisionScope_Values CHECK((EmployeeId IS NOT NULL OR SubjectId IS NOT NULL) AND(ValidTo IS NULL OR ValidTo>=ValidFrom) AND Status IN(''active'',''revoked'')));
CREATE INDEX IX_SupervisionScope_User ON academic.SupervisionScope(SchoolId,SupervisorUserId,Status,ValidFrom) INCLUDE(EmployeeId,SubjectId,ValidTo);

';
 EXEC sys.sp_executesql N'
CREATE OR ALTER FUNCTION security.CanSupervise(@user uniqueidentifier,@school uniqueidentifier,@employee uniqueidentifier,@subject uniqueidentifier,@today date) RETURNS bit AS
BEGIN
 RETURN CASE WHEN EXISTS(SELECT 1 FROM academic.SupervisionScope s WHERE s.SchoolId=@school AND s.SupervisorUserId=@user AND s.Status=''active'' AND s.ValidFrom<=@today AND(s.ValidTo IS NULL OR s.ValidTo>=@today)
 AND(s.EmployeeId IS NULL OR s.EmployeeId=@employee) AND(s.SubjectId IS NULL OR s.SubjectId=@subject OR(@subject IS NULL AND EXISTS(SELECT 1 FROM academic.TeachingAssignment a WHERE a.SchoolId=@school AND a.EmployeeId=@employee AND a.SubjectId=s.SubjectId)))) THEN 1 ELSE 0 END;
END;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER TRIGGER learning.TR_PlanVersion_Immutable ON learning.PlanVersion AFTER UPDATE,DELETE AS
BEGIN SET NOCOUNT ON;IF EXISTS(SELECT 1 FROM deleted) THROW 52560,''Plan versions are immutable; append a new version.'',1;END;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER TRIGGER learning.TR_PlanReview_Immutable ON learning.PlanReview AFTER UPDATE,DELETE AS
BEGIN SET NOCOUNT ON;IF EXISTS(SELECT 1 FROM deleted) THROW 52561,''Plan reviews are immutable.'',1;END;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER TRIGGER attendance.TR_StudentAttendance_Frozen ON attendance.StudentAttendance AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM(SELECT AttendanceSessionId FROM inserted UNION SELECT AttendanceSessionId FROM deleted) x JOIN attendance.AttendanceSession s WITH(UPDLOCK,HOLDLOCK) ON s.AttendanceSessionId=x.AttendanceSessionId WHERE s.Status IN(''submitted'',''locked'')) THROW 52566,''Submitted attendance must be reopened before changing marks.'',1;
END;
';
 EXEC sys.sp_executesql N'
DECLARE @id int,@definition nvarchar(max),@updated nvarchar(max),@changed int=0;
DECLARE guards CURSOR LOCAL FAST_FORWARD FOR
 SELECT tr.object_id FROM sys.triggers tr JOIN sys.objects o ON o.object_id=tr.object_id JOIN sys.schemas s ON s.schema_id=o.schema_id
 WHERE s.name IN(''attendance'',''academic'') AND OBJECT_DEFINITION(tr.object_id) LIKE ''%CoverAssignment%''
 AND OBJECT_DEFINITION(tr.object_id) LIKE ''%LeaveRequest%'';
OPEN guards;FETCH NEXT FROM guards INTO @id;
WHILE @@FETCH_STATUS=0
BEGIN
 SET @definition=OBJECT_DEFINITION(@id);SET @updated=@definition;
 SET @updated=REPLACE(@updated,N''OR x.CoverDate>r.EndDate OR'',N''OR x.CoverDate>r.EndDate OR (r.StartTimeLocal IS NOT NULL AND NOT EXISTS(SELECT 1 FROM academic.TimetableLesson tl JOIN academic.PeriodDefinition qp ON qp.PeriodId=tl.PeriodId WHERE tl.TimetableLessonId=x.TimetableLessonId AND r.StartTimeLocal<qp.EndTime AND qp.StartTime<r.EndTimeLocal)) OR'');
 SET @updated=REPLACE(@updated,N''x.CoverDate BETWEEN r.StartDate AND r.EndDate'',N''x.CoverDate BETWEEN r.StartDate AND r.EndDate AND(r.StartTimeLocal IS NULL OR EXISTS(SELECT 1 FROM academic.TimetableLesson tl JOIN academic.PeriodDefinition qp ON qp.PeriodId=tl.PeriodId WHERE tl.TimetableLessonId=x.TimetableLessonId AND r.StartTimeLocal<qp.EndTime AND qp.StartTime<r.EndTimeLocal))'');
 IF @updated<>@definition
 BEGIN
  SET @updated=STUFF(@updated,1,CHARINDEX(N''TRIGGER'',@updated)-1,N''ALTER '');EXEC sys.sp_executesql @updated;SET @changed+=1;
 END;
 FETCH NEXT FROM guards INTO @id;
END;
CLOSE guards;DEALLOCATE guards;
IF @changed<3 THROW 52563,''Expected coverage guards were not found; migration rolled back by runner.'',1;
';
 EXEC sys.sp_executesql N'
DECLARE @correction nvarchar(max)=OBJECT_DEFINITION(OBJECT_ID(N''learning.CreateVisitCorrection''));
IF @correction NOT LIKE N''%ScheduledAtUtc,Status,Recommendations,SupersedesVisitId)%'' THROW 52565,''Visit correction command differs from the reviewed baseline.'',1;
SET @correction=REPLACE(@correction,N''ScheduledAtUtc,Status,Recommendations,SupersedesVisitId)'',N''ScheduledAtUtc,Status,Recommendations,SupersedesVisitId,DurationMinutes)'');
SET @correction=REPLACE(@correction,N''@Reason,SupervisoryVisitId FROM'',N''@Reason,SupervisoryVisitId,DurationMinutes FROM'');
SET @correction=STUFF(@correction,1,CHARINDEX(N''PROCEDURE'',@correction)-1,N''ALTER '');EXEC sys.sp_executesql @correction;
';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(23,N''023_school_workflow_foundations.sql'',0xf12e74eb24ac0973b1ed688761ff9129ad1994c39b9d9f8e244fbb28136a3bcb,''executed'');';
 -- BEGIN 024_operational_role_boundaries.sql
 EXEC sys.sp_executesql N'SET XACT_ABORT ON;
SET NOCOUNT ON;

INSERT security.Role(Code,Name,IsSystemRole)
SELECT v.Code,v.Name,1 FROM(VALUES
 (''school_admin'',N''مسؤول إعداد المدرسة''),(''organization_owner'',N''مالك المؤسسة التعليمية''),
 (''payroll_officer'',N''مسؤول الرواتب''),(''receptionist'',N''موظف الاستقبال''),(''service_staff'',N''موظف الخدمات''))v(Code,Name)
WHERE NOT EXISTS(SELECT 1 FROM security.Role r WHERE r.Code=v.Code);

INSERT security.Permission(Code,Description)
SELECT v.Code,v.Description FROM(VALUES
 (''academic.read'',N''عرض الهيكل الأكاديمي''),(''employee.self.read'',N''عرض الملف والدوام الشخصي للموظف''),
 (''profiles.students.read'',N''عرض ملفات الطلاب''),(''profiles.students.manage'',N''إدارة ملفات الطلاب''),
 (''profiles.guardians.read'',N''عرض ملفات الأولياء''),(''profiles.guardians.manage'',N''إدارة ملفات الأولياء''),
 (''profiles.employees.read'',N''عرض ملفات الموظفين''),(''profiles.employees.manage'',N''إدارة ملفات الموظفين''),
 (''enrollments.read'',N''عرض التسجيلات''),(''enrollments.manage'',N''إدارة التسجيلات''),
 (''family.links.read'',N''عرض روابط الأسرة''),(''family.links.manage'',N''إدارة روابط الأسرة''),
 (''teaching.read'',N''عرض إسنادات التدريس''),(''teaching.manage'',N''إدارة إسنادات التدريس''),
 (''staff.attendance.manage'',N''إدارة دوام الموظفين''),(''workspace.read'',N''عرض مساحة العمل المصرح بها'')
)v(Code,Description) WHERE NOT EXISTS(SELECT 1 FROM security.Permission p WHERE p.Code=v.Code);

-- A technical account no longer acquires a school''s business authority implicitly.
DELETE rp FROM security.RolePermission rp JOIN security.Role r ON r.RoleId=rp.RoleId
JOIN security.Permission p ON p.PermissionId=rp.PermissionId
WHERE r.Code IN(''admin'',''platform_owner'') AND p.Code NOT IN(''users.read'',''users.manage'',''security.roles.manage'',''school.read'',''audit.read'');

DECLARE @grants TABLE(RoleCode varchar(60),PermissionCode varchar(120));
INSERT @grants VALUES
 (''school_admin'',''school.read''),(''school_admin'',''school.manage''),(''school_admin'',''academic.read''),
 (''school_admin'',''teaching.read''),(''school_admin'',''teaching.manage''),(''school_admin'',''supervision.assign''),
 (''admissions_officer'',''school.read''),(''admissions_officer'',''academic.read''),
 (''admissions_officer'',''profiles.students.read''),(''admissions_officer'',''profiles.students.manage''),
 (''admissions_officer'',''profiles.guardians.read''),(''admissions_officer'',''profiles.guardians.manage''),
 (''admissions_officer'',''enrollments.read''),(''admissions_officer'',''enrollments.manage''),
 (''admissions_officer'',''family.links.read''),(''admissions_officer'',''family.links.manage''),
 (''hr_officer'',''school.read''),(''hr_officer'',''profiles.employees.read''),(''hr_officer'',''profiles.employees.manage''),
 (''hr_officer'',''leave.decide''),(''hr_officer'',''leave.balances.manage''),(''hr_officer'',''staff.attendance.manage''),
 (''principal'',''academic.read''),(''principal'',''teaching.read''),(''principal'',''staff.attendance.manage''),
 (''payroll_officer'',''school.read''),(''payroll_officer'',''payroll.read''),(''payroll_officer'',''payroll.manage''),
 (''finance_officer'',''school.read''),(''receptionist'',''school.read''),(''service_staff'',''school.read''),
 (''clinic_staff'',''school.read''),(''transport_officer'',''school.read''),
 (''organization_owner'',''school.read''),(''platform_owner'',''workspace.read'');

-- HR and payroll are separate functions. Existing HR accounts keep personnel/leave work.
DELETE rp FROM security.RolePermission rp JOIN security.Role r ON r.RoleId=rp.RoleId
JOIN security.Permission p ON p.PermissionId=rp.PermissionId
WHERE r.Code=''hr_officer'' AND p.Code IN(''payroll.read'',''payroll.manage'');

INSERT @grants SELECT Code,''workspace.read'' FROM security.Role WHERE Code IN
 (''school_admin'',''organization_owner'',''finance_officer'',''hr_officer'',''payroll_officer'',''admissions_officer'',''receptionist'',''service_staff'',''clinic_staff'',''transport_officer'');
INSERT @grants SELECT r.Code,p.Code FROM security.Role r CROSS JOIN(VALUES(''leave.request''),(''files.upload''),(''employee.self.read''))p(Code)
WHERE r.Code IN(''school_admin'',''principal'',''supervisor'',''teacher'',''finance_officer'',''hr_officer'',''payroll_officer'',''admissions_officer'',''receptionist'',''service_staff'',''clinic_staff'',''transport_officer'');
INSERT security.RolePermission(RoleId,PermissionId)
SELECT r.RoleId,p.PermissionId FROM @grants g JOIN security.Role r ON r.Code=g.RoleCode
JOIN security.Permission p ON p.Code=g.PermissionCode
WHERE NOT EXISTS(SELECT 1 FROM security.RolePermission rp WHERE rp.RoleId=r.RoleId AND rp.PermissionId=p.PermissionId);
';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(24,N''024_operational_role_boundaries.sql'',0x77e184a7d2128c83b09e948645d68fef4495795cc17bb7a5715d0a1c4d840693,''executed'');';
 -- BEGIN 025_finance_workflows.sql
 EXEC sys.sp_executesql N'SET XACT_ABORT ON;
SET NOCOUNT ON;

CREATE TABLE finance.CommandResult(
 SchoolId uniqueidentifier NOT NULL,
 RequestId uniqueidentifier NOT NULL,
 ActorUserId uniqueidentifier NOT NULL,
 Operation varchar(40) NOT NULL,
 PayloadHash binary(32) NOT NULL,
 ResultId uniqueidentifier NOT NULL,
 CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_FinanceCommand_Created DEFAULT SYSUTCDATETIME(),
 CONSTRAINT PK_FinanceCommand PRIMARY KEY(SchoolId,RequestId),
 CONSTRAINT FK_FinanceCommand_School FOREIGN KEY(SchoolId) REFERENCES core.School(SchoolId),
 CONSTRAINT FK_FinanceCommand_Actor FOREIGN KEY(ActorUserId) REFERENCES security.UserAccount(UserId)
);
CREATE TABLE finance.ApprovalRequest(
 ApprovalRequestId uniqueidentifier NOT NULL CONSTRAINT DF_FinanceApproval_Id DEFAULT NEWSEQUENTIALID(),
 SchoolId uniqueidentifier NOT NULL,
 ChargeId uniqueidentifier NOT NULL,
 PaymentId uniqueidentifier NULL,
 RequestType varchar(24) NOT NULL,
 Amount decimal(19,4) NOT NULL,
 Reason nvarchar(1000) NOT NULL,
 RequestedByUserId uniqueidentifier NOT NULL,
 CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_FinanceApproval_Created DEFAULT SYSUTCDATETIME(),
 Status varchar(20) NOT NULL CONSTRAINT DF_FinanceApproval_Status DEFAULT ''pending'',
 DecidedByUserId uniqueidentifier NULL,
 DecidedAtUtc datetime2(3) NULL,
 DecisionNote nvarchar(1000) NULL,
 RowVersion rowversion NOT NULL,
 CONSTRAINT PK_FinanceApproval PRIMARY KEY(ApprovalRequestId),
 CONSTRAINT UQ_FinanceApproval_Scope UNIQUE(SchoolId,ApprovalRequestId),
 CONSTRAINT FK_FinanceApproval_Charge FOREIGN KEY(SchoolId,ChargeId) REFERENCES finance.Charge(SchoolId,ChargeId),
 CONSTRAINT FK_FinanceApproval_Payment FOREIGN KEY(SchoolId,PaymentId) REFERENCES finance.Payment(SchoolId,PaymentId),
 CONSTRAINT FK_FinanceApproval_Maker FOREIGN KEY(RequestedByUserId) REFERENCES security.UserAccount(UserId),
 CONSTRAINT FK_FinanceApproval_Checker FOREIGN KEY(DecidedByUserId) REFERENCES security.UserAccount(UserId),
 CONSTRAINT CK_FinanceApproval_Type CHECK((RequestType IN(''discount'',''cancel_charge'') AND PaymentId IS NULL) OR(RequestType=''refund'' AND PaymentId IS NOT NULL)),
 CONSTRAINT CK_FinanceApproval_Amount CHECK(Amount>0),
 CONSTRAINT CK_FinanceApproval_Reason CHECK(LEN(LTRIM(RTRIM(Reason)))>0),
 CONSTRAINT CK_FinanceApproval_Decision CHECK(
  (Status=''pending'' AND DecidedByUserId IS NULL AND DecidedAtUtc IS NULL AND DecisionNote IS NULL)
  OR(Status IN(''approved'',''rejected'') AND DecidedByUserId IS NOT NULL AND DecidedAtUtc IS NOT NULL AND DecisionNote IS NOT NULL AND LEN(LTRIM(RTRIM(DecisionNote)))>0 AND RequestedByUserId<>DecidedByUserId))
);
CREATE INDEX IX_FinanceApproval_Status ON finance.ApprovalRequest(SchoolId,Status,CreatedAtUtc) INCLUDE(ChargeId,RequestType,Amount);
INSERT security.Permission(Code,Description) SELECT ''finance.approve'',N''اعتماد الخصومات والإرجاع وإلغاء الرسوم بفصل المعد عن المعتمد'' WHERE NOT EXISTS(SELECT 1 FROM security.Permission WHERE Code=''finance.approve'');
INSERT security.RolePermission(RoleId,PermissionId)
SELECT r.RoleId,p.PermissionId FROM security.Role r CROSS JOIN security.Permission p
WHERE r.Code=''principal'' AND p.Code IN(''finance.approve'',''finance.read'') AND NOT EXISTS(SELECT 1 FROM security.RolePermission x WHERE x.RoleId=r.RoleId AND x.PermissionId=p.PermissionId);';
 EXEC sys.sp_executesql N'
EXEC(N''CREATE OR ALTER TRIGGER finance.TR_ApprovalRequest_History ON finance.ApprovalRequest AFTER UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM deleted d LEFT JOIN inserted i ON i.ApprovalRequestId=d.ApprovalRequestId WHERE i.ApprovalRequestId IS NULL OR d.Status<>''''pending'''' OR i.Status NOT IN(''''approved'''',''''rejected'''') OR i.SchoolId<>d.SchoolId OR i.ChargeId<>d.ChargeId OR ISNULL(CONVERT(varchar(36),i.PaymentId),'''''''')<>ISNULL(CONVERT(varchar(36),d.PaymentId),'''''''') OR i.RequestType<>d.RequestType OR i.Amount<>d.Amount OR i.Reason<>d.Reason OR i.RequestedByUserId<>d.RequestedByUserId OR i.CreatedAtUtc<>d.CreatedAtUtc)
 THROW 52101,''''Finance approval history is immutable.'''',1;
END;'');';
 EXEC sys.sp_executesql N'
EXEC(N''-- This module owns the privileged append; the runtime cannot directly insert reversals.
CREATE OR ALTER PROCEDURE finance.PostApprovedRefund @SchoolId uniqueidentifier,@RequestId uniqueidentifier,@ActorUserId uniqueidentifier
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @payment uniqueidentifier,@amount decimal(19,4),@reason nvarchar(1000),@original decimal(19,4),@reversed decimal(19,4);
 IF @@TRANCOUNT=0 THROW 52102,''''Refund requires the approval transaction.'''',1;
 IF security.HasSchoolPermission(@ActorUserId,@SchoolId,''''finance.approve'''')=0 THROW 52103,''''Independent finance approval permission required.'''',1;
 SELECT @payment=PaymentId,@amount=Amount,@reason=Reason FROM finance.ApprovalRequest WITH(UPDLOCK,HOLDLOCK)
 WHERE SchoolId=@SchoolId AND ApprovalRequestId=@RequestId AND RequestType=''''refund'''' AND Status=''''approved'''' AND DecidedByUserId=@ActorUserId AND RequestedByUserId<>@ActorUserId;
 IF @payment IS NULL THROW 52104,''''Approved refund request required.'''',1;
 IF EXISTS(SELECT 1 FROM finance.PaymentReversal WHERE PaymentReversalId=@RequestId) RETURN;
 SELECT @original=Amount FROM finance.Payment WITH(UPDLOCK,HOLDLOCK) WHERE SchoolId=@SchoolId AND PaymentId=@payment;
 SELECT @reversed=COALESCE(SUM(Amount),0) FROM finance.PaymentReversal WITH(UPDLOCK,HOLDLOCK) WHERE SchoolId=@SchoolId AND PaymentId=@payment;
 IF @original IS NULL OR @reversed+@amount>@original THROW 52105,''''Refund exceeds remaining paid amount.'''',1;
 INSERT finance.PaymentReversal(PaymentReversalId,SchoolId,PaymentId,Amount,Reason,ExternalReference,ApprovedByUserId)
 VALUES(@RequestId,@SchoolId,@payment,@amount,@reason,CONCAT(N''''APPROVAL-'''',CONVERT(nvarchar(36),@RequestId)),@ActorUserId);
 UPDATE finance.Payment SET Status=CASE WHEN @reversed+@amount=@original THEN ''''refunded'''' ELSE ''''partially_refunded'''' END WHERE SchoolId=@SchoolId AND PaymentId=@payment;
END;'');';
 EXEC sys.sp_executesql N'
GRANT SELECT,INSERT ON finance.CommandResult TO awn_backend;
DENY UPDATE,DELETE ON finance.CommandResult TO awn_backend;
GRANT SELECT,INSERT,UPDATE ON finance.ApprovalRequest TO awn_backend;
DENY DELETE ON finance.ApprovalRequest TO awn_backend;
GRANT EXECUTE ON finance.PostApprovedRefund TO awn_backend;
-- The application''s financial policy now requires independent principal approval.
DENY EXECUTE ON finance.ReversePayment TO awn_backend;
';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(25,N''025_finance_workflows.sql'',0x17ec21cab1cf7f56c9f4db8b341e821070e575b97c0bdb0e616e1edfe1ecf106,''executed'');';
 -- BEGIN 026_assessment_workflows.sql
 EXEC sys.sp_executesql N'SET NOCOUNT ON;
SET XACT_ABORT ON;
ALTER TABLE assessment.Question ADD CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_Question_Created DEFAULT SYSUTCDATETIME(),Revision rowversion;
ALTER TABLE assessment.Exam ADD ReviewStatus varchar(20) NOT NULL CONSTRAINT DF_Exam_ReviewStatus DEFAULT ''draft'',ReviewCycle int NOT NULL CONSTRAINT DF_Exam_ReviewCycle DEFAULT 0,OpensOnSchoolDate date NULL,ResultsReleasedAtUtc datetime2(3) NULL,Revision rowversion;';
 EXEC sys.sp_executesql N'
ALTER TABLE assessment.Exam ADD CONSTRAINT CK_Exam_ReviewStatus CHECK(ReviewStatus IN(''draft'',''submitted'',''approved'',''returned''));
ALTER TABLE assessment.Exam ADD CONSTRAINT CK_Exam_ReleaseClosed CHECK(ResultsReleasedAtUtc IS NULL OR Status IN(''closed'',''archived''));
ALTER TABLE assessment.ExamAttempt ADD DeadlineAtUtc datetime2(3) NULL,GradedAtUtc datetime2(3) NULL,Revision rowversion;
CREATE TABLE assessment.ExamReview(
 ExamReviewId uniqueidentifier NOT NULL CONSTRAINT DF_ExamReview_Id DEFAULT NEWSEQUENTIALID(),SchoolId uniqueidentifier NOT NULL,ExamId uniqueidentifier NOT NULL,ReviewCycle int NOT NULL,Decision varchar(20) NOT NULL,Comments nvarchar(3000) NOT NULL,ReviewedByUserId uniqueidentifier NOT NULL,ReviewedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_ExamReview_Created DEFAULT SYSUTCDATETIME(),
 CONSTRAINT PK_ExamReview PRIMARY KEY(ExamReviewId),CONSTRAINT FK_ExamReview_Exam FOREIGN KEY(SchoolId,ExamId)REFERENCES assessment.Exam(SchoolId,ExamId),CONSTRAINT FK_ExamReview_Actor FOREIGN KEY(ReviewedByUserId)REFERENCES security.UserAccount(UserId),CONSTRAINT UQ_ExamReview_Cycle UNIQUE(SchoolId,ExamId,ReviewCycle),CONSTRAINT CK_ExamReview_Decision CHECK(Decision IN(''approved'',''returned'') AND ReviewCycle>0 AND LEN(LTRIM(RTRIM(Comments)))>0)
);
CREATE TABLE assessment.ExamResponseRevision(
 ExamResponseRevisionId uniqueidentifier NOT NULL CONSTRAINT DF_ExamResponseRevision_Id DEFAULT NEWSEQUENTIALID(),SchoolId uniqueidentifier NOT NULL,ExamResponseId uniqueidentifier NOT NULL,Score decimal(9,4) NOT NULL,Feedback nvarchar(2000) NULL,GradedByUserId uniqueidentifier NOT NULL,CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_ExamResponseRevision_Created DEFAULT SYSUTCDATETIME(),
 CONSTRAINT PK_ExamResponseRevision PRIMARY KEY(ExamResponseRevisionId),CONSTRAINT FK_ExamResponseRevision_Response FOREIGN KEY(SchoolId,ExamResponseId) REFERENCES assessment.ExamResponse(SchoolId,ExamResponseId),CONSTRAINT FK_ExamResponseRevision_Actor FOREIGN KEY(GradedByUserId) REFERENCES security.UserAccount(UserId),CONSTRAINT CK_ExamResponseRevision_Score CHECK(Score>=0)
);
INSERT security.Permission(Code,Description) SELECT v.Code,v.Name FROM(VALUES(''questions.read'',N''عرض أسئلة المعلم أو المعلمين المسندين''),(''questions.manage'',N''إنشاء إصدارات الأسئلة''),(''exams.manage'',N''إعداد الاختبارات ونشرها وتصحيحها وإعلانها''),(''exams.review'',N''مراجعة اختبار معلم ومادة مسندين''),(''exams.take'',N''أداء اختبار للشعبة المسجل بها الطالب''))v(Code,Name) WHERE NOT EXISTS(SELECT 1 FROM security.Permission p WHERE p.Code=v.Code);
INSERT security.RolePermission(RoleId,PermissionId) SELECT r.RoleId,p.PermissionId FROM(VALUES(''teacher'',''questions.read''),(''teacher'',''questions.manage''),(''teacher'',''exams.manage''),(''supervisor'',''questions.read''),(''supervisor'',''exams.review''),(''student'',''exams.take''))v(RoleCode,PermissionCode)JOIN security.Role r ON r.Code=v.RoleCode JOIN security.Permission p ON p.Code=v.PermissionCode WHERE NOT EXISTS(SELECT 1 FROM security.RolePermission x WHERE x.RoleId=r.RoleId AND x.PermissionId=p.PermissionId);';
 EXEC sys.sp_executesql N'
EXEC(N''CREATE OR ALTER TRIGGER assessment.TR_ExamReview_Immutable ON assessment.ExamReview AFTER UPDATE,DELETE AS BEGIN SET NOCOUNT ON;IF EXISTS(SELECT 1 FROM deleted)THROW 52601,''''Exam review history is immutable.'''',1;END;'');
EXEC(N''CREATE OR ALTER TRIGGER assessment.TR_ExamResponseRevision_Immutable ON assessment.ExamResponseRevision AFTER UPDATE,DELETE AS BEGIN SET NOCOUNT ON;IF EXISTS(SELECT 1 FROM deleted)THROW 52602,''''Exam grading history is immutable.'''',1;END;'');
GRANT SELECT,INSERT ON assessment.ExamReview TO awn_backend;
GRANT SELECT,INSERT ON assessment.ExamResponseRevision TO awn_backend;
DENY UPDATE,DELETE ON assessment.ExamReview TO awn_backend;
DENY UPDATE,DELETE ON assessment.ExamResponseRevision TO awn_backend;';
 EXEC sys.sp_executesql N'
EXEC(N''CREATE OR ALTER TRIGGER assessment.TR_ExamQuestion_WorkflowFrozen ON assessment.ExamQuestion AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON;IF EXISTS(SELECT 1 FROM (SELECT SchoolId,ExamId FROM inserted UNION SELECT SchoolId,ExamId FROM deleted)x JOIN assessment.Exam e ON e.SchoolId=x.SchoolId AND e.ExamId=x.ExamId WHERE e.Status<>''''draft'''' OR e.ReviewStatus IN(''''submitted'''',''''approved''''))THROW 52604,''''Reviewed or released exam questions are frozen.'''',1;END;'');
EXEC(N''CREATE OR ALTER TRIGGER assessment.TR_Exam_ResponseHistoryBounds ON assessment.ExamResponseRevision AFTER INSERT AS BEGIN SET NOCOUNT ON;IF EXISTS(SELECT 1 FROM inserted i JOIN assessment.ExamResponse r ON r.SchoolId=i.SchoolId AND r.ExamResponseId=i.ExamResponseId JOIN assessment.ExamQuestion q ON q.SchoolId=r.SchoolId AND q.ExamQuestionId=r.ExamQuestionId WHERE i.Score>q.MaximumScore)THROW 52605,''''Historical score exceeds question maximum.'''',1;END;'');
EXEC(N''CREATE OR ALTER TRIGGER assessment.TR_Exam_ReleasedIdentity ON assessment.Exam AFTER UPDATE,DELETE AS BEGIN SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM deleted d LEFT JOIN inserted i ON i.ExamId=d.ExamId WHERE i.ExamId IS NULL OR d.Status<>''''draft'''' AND(i.SchoolId<>d.SchoolId OR i.TeachingAssignmentId<>d.TeachingAssignmentId OR i.Title<>d.Title OR i.OpensAtUtc<>d.OpensAtUtc OR ISNULL(CONVERT(char(10),i.OpensOnSchoolDate,23),'''''''')<>ISNULL(CONVERT(char(10),d.OpensOnSchoolDate,23),'''''''') OR i.ClosesAtUtc<>d.ClosesAtUtc OR i.DurationMinutes<>d.DurationMinutes OR i.MaximumAttempts<>d.MaximumAttempts OR i.ReviewStatus<>d.ReviewStatus OR i.ReviewCycle<>d.ReviewCycle OR i.Status=''''draft'''' OR d.ResultsReleasedAtUtc IS NOT NULL AND(i.ResultsReleasedAtUtc IS NULL OR i.ResultsReleasedAtUtc<>d.ResultsReleasedAtUtc)))THROW 52606,''''Published exam identity is immutable.'''',1;
 IF EXISTS(SELECT 1 FROM inserted i JOIN assessment.ExamAttempt a ON a.SchoolId=i.SchoolId AND a.ExamId=i.ExamId WHERE i.ResultsReleasedAtUtc IS NOT NULL AND a.Status NOT IN(''''graded'''',''''void''''))THROW 52607,''''Approve grading before releasing results.'''',1;
END;'');';
 EXEC sys.sp_executesql N'
EXEC(N''CREATE OR ALTER TRIGGER assessment.TR_ExamResponse_WorkflowFrozen ON assessment.ExamResponse AFTER UPDATE,DELETE AS BEGIN SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM deleted d JOIN assessment.ExamAttempt a ON a.SchoolId=d.SchoolId AND a.ExamAttemptId=d.ExamAttemptId LEFT JOIN inserted i ON i.ExamResponseId=d.ExamResponseId WHERE a.Status<>''''in_progress'''' AND(i.ExamResponseId IS NULL OR i.AnswerJson<>d.AnswerJson OR i.ExamId<>d.ExamId OR i.ExamQuestionId<>d.ExamQuestionId OR i.ExamAttemptId<>d.ExamAttemptId))THROW 52608,''''Submitted answers are immutable.'''',1;
 IF EXISTS(SELECT 1 FROM deleted d JOIN assessment.Exam e ON e.SchoolId=d.SchoolId AND e.ExamId=d.ExamId LEFT JOIN inserted i ON i.ExamResponseId=d.ExamResponseId WHERE e.ResultsReleasedAtUtc IS NOT NULL AND(i.ExamResponseId IS NULL OR ISNULL(i.Score,-1)<>ISNULL(d.Score,-1) OR ISNULL(i.Feedback,N'''''''')<>ISNULL(d.Feedback,N'''''''')))THROW 52609,''''Announced scores are frozen.'''',1;
END;'');
EXEC(N''CREATE OR ALTER TRIGGER assessment.TR_ExamAttempt_WorkflowFrozen ON assessment.ExamAttempt AFTER UPDATE,DELETE AS BEGIN SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM deleted d LEFT JOIN inserted i ON i.ExamAttemptId=d.ExamAttemptId JOIN assessment.Exam e ON e.SchoolId=d.SchoolId AND e.ExamId=d.ExamId WHERE i.ExamAttemptId IS NULL OR i.ExamId<>d.ExamId OR i.EnrollmentId<>d.EnrollmentId OR i.AttemptNo<>d.AttemptNo OR i.StartedAtUtc<>d.StartedAtUtc OR ISNULL(i.DeadlineAtUtc,''''99991231'''')<>ISNULL(d.DeadlineAtUtc,''''99991231'''') OR d.SubmittedAtUtc IS NOT NULL AND(i.SubmittedAtUtc IS NULL OR i.SubmittedAtUtc<>d.SubmittedAtUtc) OR d.Status<>''''in_progress'''' AND i.Status=''''in_progress'''' OR e.ResultsReleasedAtUtc IS NOT NULL AND i.Status<>d.Status)THROW 52610,''''Attempt identity and submission cannot be reset.'''',1;
END;'');
';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(26,N''026_assessment_workflows.sql'',0x14eb0b7124eacccd4fc6b482f1b5e1569164f97ab67d01cad3ba5adf54349fde,''executed'');';
 -- BEGIN 027_learning_workflows.sql
 EXEC sys.sp_executesql N'SET NOCOUNT ON;
SET XACT_ABORT ON;
ALTER TABLE learning.Assignment ADD DueAtUtc datetime2(3) NULL,PublishedOnSchoolDate date NULL,AllowLate bit NOT NULL CONSTRAINT DF_Assignment_AllowLate DEFAULT 1;
ALTER TABLE learning.Resource ADD ExternalUrl nvarchar(2048) NULL,Revision rowversion;';
 EXEC sys.sp_executesql N'
UPDATE a SET DueAtUtc=CONVERT(datetime2(3),a.DueAtLocal AT TIME ZONE s.TimeZoneId AT TIME ZONE ''UTC''),PublishedOnSchoolDate=CONVERT(date,a.CreatedAtUtc AT TIME ZONE ''UTC'' AT TIME ZONE s.TimeZoneId) FROM learning.Assignment a JOIN core.School s ON s.SchoolId=a.SchoolId;
ALTER TABLE learning.Assignment ALTER COLUMN DueAtUtc datetime2(3) NOT NULL;
CREATE TABLE learning.SubmissionReview(
 SubmissionReviewId uniqueidentifier NOT NULL CONSTRAINT DF_SubmissionReview_Id DEFAULT NEWSEQUENTIALID(),SchoolId uniqueidentifier NOT NULL,SubmissionRevisionId uniqueidentifier NOT NULL,Decision varchar(12) NOT NULL,Score decimal(9,4) NULL,Feedback nvarchar(3000) NULL,ReviewedByUserId uniqueidentifier NOT NULL,ReviewedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_SubmissionReview_At DEFAULT SYSUTCDATETIME(),ReleasedAtUtc datetime2(3) NULL,
 CONSTRAINT PK_SubmissionReview PRIMARY KEY(SubmissionReviewId),CONSTRAINT UQ_SubmissionReview_Revision UNIQUE(SchoolId,SubmissionRevisionId),CONSTRAINT FK_SubmissionReview_Revision FOREIGN KEY(SchoolId,SubmissionRevisionId) REFERENCES learning.SubmissionRevision(SchoolId,SubmissionRevisionId),CONSTRAINT FK_SubmissionReview_Actor FOREIGN KEY(ReviewedByUserId) REFERENCES security.UserAccount(UserId),CONSTRAINT CK_SubmissionReview_Decision CHECK((Decision=''graded'' AND Score IS NOT NULL AND Score>=0) OR(Decision=''returned'' AND Score IS NULL AND LEN(LTRIM(RTRIM(Feedback)))>0)),CONSTRAINT CK_SubmissionReview_Release CHECK(ReleasedAtUtc IS NULL OR (Decision=''graded'' AND ReleasedAtUtc>=ReviewedAtUtc))
);
CREATE INDEX IX_SubmissionReview_Unreleased ON learning.SubmissionReview(SchoolId,ReleasedAtUtc) INCLUDE(SubmissionRevisionId,Decision);
INSERT security.Permission(Code,Description) SELECT v.Code,v.Name FROM(VALUES(''resources.read'',N''قراءة المصادر التعليمية المتاحة''),(''resources.manage'',N''إدارة مصادر المعلم لإسناداته''))v(Code,Name) WHERE NOT EXISTS(SELECT 1 FROM security.Permission p WHERE p.Code=v.Code);
INSERT security.RolePermission(RoleId,PermissionId) SELECT r.RoleId,p.PermissionId FROM(VALUES(''teacher'',''resources.manage''),(''student'',''resources.read''))v(RoleCode,PermissionCode)JOIN security.Role r ON r.Code=v.RoleCode JOIN security.Permission p ON p.Code=v.PermissionCode WHERE NOT EXISTS(SELECT 1 FROM security.RolePermission x WHERE x.RoleId=r.RoleId AND x.PermissionId=p.PermissionId);';
 EXEC sys.sp_executesql N'
EXEC(N''CREATE OR ALTER TRIGGER learning.TR_Assignment_PublishedFrozen ON learning.Assignment AFTER UPDATE,DELETE AS BEGIN SET NOCOUNT ON;IF EXISTS(SELECT 1 FROM deleted d LEFT JOIN inserted i ON i.AssignmentId=d.AssignmentId WHERE d.Status<>''''draft'''' AND(i.AssignmentId IS NULL OR EXISTS(SELECT d.SchoolId,d.TeachingAssignmentId,d.Title,d.Instructions,d.DueAtLocal,d.DueAtUtc,d.MaximumScore,d.AllowLate,d.CreatedByUserId,d.PublishedOnSchoolDate EXCEPT SELECT i.SchoolId,i.TeachingAssignmentId,i.Title,i.Instructions,i.DueAtLocal,i.DueAtUtc,i.MaximumScore,i.AllowLate,i.CreatedByUserId,i.PublishedOnSchoolDate) OR NOT(d.Status=i.Status OR(d.Status=''''published'''' AND i.Status=''''closed'''') OR(d.Status=''''closed'''' AND i.Status=''''archived'''')))) THROW 52701,''''Published assignment is immutable.'''',1;END;'');
EXEC(N''CREATE OR ALTER TRIGGER learning.TR_AssignmentFile_Frozen ON learning.AssignmentFile AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON;IF EXISTS(SELECT 1 FROM(SELECT SchoolId,AssignmentId FROM inserted UNION SELECT SchoolId,AssignmentId FROM deleted)x JOIN learning.Assignment a ON a.SchoolId=x.SchoolId AND a.AssignmentId=x.AssignmentId WHERE a.Status<>''''draft'''') THROW 52702,''''Published materials are immutable.'''',1;END;'');
EXEC(N''CREATE OR ALTER TRIGGER learning.TR_SubmissionRevision_AppendOnly ON learning.SubmissionRevision AFTER UPDATE,DELETE AS BEGIN SET NOCOUNT ON;IF EXISTS(SELECT 1 FROM deleted) THROW 52703,''''Submission revisions are append only.'''',1;END;'');
EXEC(N''CREATE OR ALTER TRIGGER learning.TR_SubmissionReview_Integrity ON learning.SubmissionReview AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON;IF EXISTS(SELECT 1 FROM deleted d LEFT JOIN inserted i ON i.SubmissionReviewId=d.SubmissionReviewId WHERE i.SubmissionReviewId IS NULL OR d.ReleasedAtUtc IS NOT NULL OR i.ReleasedAtUtc IS NULL OR EXISTS(SELECT d.SchoolId,d.SubmissionRevisionId,d.Decision,d.Score,d.Feedback,d.ReviewedByUserId,d.ReviewedAtUtc EXCEPT SELECT i.SchoolId,i.SubmissionRevisionId,i.Decision,i.Score,i.Feedback,i.ReviewedByUserId,i.ReviewedAtUtc)) THROW 52704,''''Review history is immutable except first publication.'''',1;IF EXISTS(SELECT 1 FROM inserted i JOIN learning.SubmissionRevision r ON r.SubmissionRevisionId=i.SubmissionRevisionId JOIN learning.Submission s ON s.SubmissionId=r.SubmissionId JOIN learning.Assignment a ON a.AssignmentId=s.AssignmentId WHERE r.SubmittedAtUtc IS NULL OR r.RevisionNo<>s.CurrentRevisionNo OR i.Score>a.MaximumScore) THROW 52705,''''Review must match current submitted revision and score limit.'''',1;END;'');
EXEC(N''CREATE OR ALTER TRIGGER learning.TR_SubmissionRevisionFile_Frozen ON learning.SubmissionRevisionFile AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON;IF EXISTS(SELECT 1 FROM deleted) THROW 52706,''''Submission files are append only.'''',1;IF EXISTS(SELECT 1 FROM inserted i JOIN learning.SubmissionRevision r ON r.SubmissionRevisionId=i.SubmissionRevisionId JOIN learning.Submission s ON s.SubmissionId=r.SubmissionId WHERE r.RevisionNo<>s.CurrentRevisionNo OR s.Status NOT IN(''''draft'''',''''returned'''')) THROW 52706,''''Files must belong to a current editable revision.'''',1;END;'');
EXEC(N''CREATE OR ALTER TRIGGER learning.TR_Resource_PublishedFrozen ON learning.Resource AFTER UPDATE,DELETE AS BEGIN SET NOCOUNT ON;IF EXISTS(SELECT 1 FROM deleted d LEFT JOIN inserted i ON i.ResourceId=d.ResourceId WHERE d.Status<>''''draft'''' AND(i.ResourceId IS NULL OR i.Status NOT IN(''''published'''',''''archived'''') OR(d.Status=''''archived'''' AND i.Status<>''''archived'''') OR EXISTS(SELECT d.SchoolId,d.SubjectId,d.Title,d.Description,d.ResourceType,d.Visibility,d.TargetTeachingAssignmentId,d.TargetClassSectionId,d.TargetStageId,d.TargetGradeLevelId,d.ExternalUrl,d.CreatedByUserId,d.PublishedAtUtc EXCEPT SELECT i.SchoolId,i.SubjectId,i.Title,i.Description,i.ResourceType,i.Visibility,i.TargetTeachingAssignmentId,i.TargetClassSectionId,i.TargetStageId,i.TargetGradeLevelId,i.ExternalUrl,i.CreatedByUserId,i.PublishedAtUtc))) THROW 52707,''''Published resource is immutable.'''',1;END;'');
EXEC(N''CREATE OR ALTER TRIGGER learning.TR_ResourceFile_Frozen ON learning.ResourceFile AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON;IF EXISTS(SELECT 1 FROM(SELECT SchoolId,ResourceId FROM inserted UNION SELECT SchoolId,ResourceId FROM deleted)x JOIN learning.Resource r ON r.SchoolId=x.SchoolId AND r.ResourceId=x.ResourceId WHERE r.Status<>''''draft'''') THROW 52708,''''Published resource files are immutable.'''',1;END;'');

GRANT SELECT,INSERT ON learning.SubmissionReview TO awn_backend;
GRANT UPDATE(ReleasedAtUtc) ON learning.SubmissionReview TO awn_backend;
DENY DELETE ON learning.SubmissionReview TO awn_backend;';
 EXEC sys.sp_executesql N'
EXEC(N''CREATE OR ALTER TRIGGER learning.TR_Submission_WorkflowFrozen ON learning.Submission AFTER UPDATE,DELETE AS BEGIN SET NOCOUNT ON;
IF EXISTS(SELECT 1 FROM deleted d LEFT JOIN inserted i ON i.SubmissionId=d.SubmissionId WHERE i.SubmissionId IS NULL OR i.SchoolId<>d.SchoolId OR i.AssignmentId<>d.AssignmentId OR i.EnrollmentId<>d.EnrollmentId OR i.CurrentRevisionNo<d.CurrentRevisionNo OR i.CurrentRevisionNo>d.CurrentRevisionNo+1 OR(i.CurrentRevisionNo<>d.CurrentRevisionNo AND(d.Status NOT IN(''''draft'''',''''returned'''') OR i.Status<>''''draft'''')) OR NOT(d.Status=i.Status OR(d.Status=''''draft'''' AND i.Status IN(''''submitted'''',''''late'''')) OR(d.Status IN(''''submitted'''',''''late'''') AND i.Status IN(''''graded'''',''''returned'''')) OR(d.Status=''''returned'''' AND i.Status=''''draft''''))) THROW 52710,''''Submission identity and workflow cannot be reset.'''',1;
END;'');
';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(27,N''027_learning_workflows.sql'',0x07a181b286c879c4d007d23bd03728cced6a4d9c4ebf6515755065b8dc2fd8fd,''executed'');';
 -- BEGIN 028_grading_workflows.sql
 EXEC sys.sp_executesql N'SET NOCOUNT ON;
SET XACT_ABORT ON;
ALTER TABLE assessment.GradingPolicy ADD Title nvarchar(200) NULL,TotalMaximum decimal(9,4) NULL,ReviewStatus varchar(20) NOT NULL CONSTRAINT DF_GradingPolicy_Review DEFAULT ''draft'';
ALTER TABLE assessment.Certificate ADD EncryptedToken nvarchar(2000) NULL;';
 EXEC sys.sp_executesql N'
UPDATE assessment.GradingPolicy SET Title=Code,TotalMaximum=CASE WHEN AssessmentMode=''descriptive'' THEN NULL ELSE 100 END,ReviewStatus=CASE WHEN Status=''draft'' THEN ''draft'' ELSE ''approved'' END;
ALTER TABLE assessment.GradingPolicy ALTER COLUMN Title nvarchar(200) NOT NULL;
ALTER TABLE assessment.GradingPolicy ADD CONSTRAINT CK_GradingPolicy_Review CHECK(ReviewStatus IN(''draft'',''submitted'',''approved'',''returned'')),CONSTRAINT CK_GradingPolicy_Total CHECK((AssessmentMode=''descriptive'' AND TotalMaximum IS NULL) OR(AssessmentMode<>''descriptive'' AND TotalMaximum IS NOT NULL AND TotalMaximum>0));
CREATE TABLE assessment.GradingLevel(
 SchoolId uniqueidentifier NOT NULL,GradingPolicyId uniqueidentifier NOT NULL,Name nvarchar(100) NOT NULL,SortOrder smallint NOT NULL,
 CONSTRAINT PK_GradingLevel PRIMARY KEY(SchoolId,GradingPolicyId,Name),CONSTRAINT FK_GradingLevel_Policy FOREIGN KEY(SchoolId,GradingPolicyId) REFERENCES assessment.GradingPolicy(SchoolId,GradingPolicyId),CONSTRAINT CK_GradingLevel_Order CHECK(SortOrder>=0)
);
CREATE TABLE assessment.PolicyReview(
 PolicyReviewId uniqueidentifier NOT NULL CONSTRAINT DF_PolicyReview_Id DEFAULT NEWSEQUENTIALID(),SchoolId uniqueidentifier NOT NULL,GradingPolicyId uniqueidentifier NOT NULL,Decision varchar(20) NOT NULL,Note nvarchar(2000) NOT NULL,ActorUserId uniqueidentifier NOT NULL,CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_PolicyReview_At DEFAULT SYSUTCDATETIME(),
 CONSTRAINT PK_PolicyReview PRIMARY KEY(PolicyReviewId),CONSTRAINT FK_PolicyReview_Policy FOREIGN KEY(SchoolId,GradingPolicyId) REFERENCES assessment.GradingPolicy(SchoolId,GradingPolicyId),CONSTRAINT FK_PolicyReview_Actor FOREIGN KEY(ActorUserId) REFERENCES security.UserAccount(UserId),CONSTRAINT CK_PolicyReview_Decision CHECK(Decision IN(''submitted'',''approved'',''returned'',''retired'') AND LEN(LTRIM(RTRIM(Note)))>0)
);
CREATE TABLE assessment.GradebookEnrollment(
 SchoolId uniqueidentifier NOT NULL,GradebookId uniqueidentifier NOT NULL,EnrollmentId uniqueidentifier NOT NULL,StudentName nvarchar(300) NOT NULL,StudentCode nvarchar(80) NOT NULL,
 CONSTRAINT PK_GradebookEnrollment PRIMARY KEY(SchoolId,GradebookId,EnrollmentId),CONSTRAINT FK_GradebookEnrollment_Book FOREIGN KEY(SchoolId,GradebookId) REFERENCES assessment.Gradebook(SchoolId,GradebookId),CONSTRAINT FK_GradebookEnrollment_Enrollment FOREIGN KEY(SchoolId,EnrollmentId) REFERENCES people.StudentEnrollment(SchoolId,EnrollmentId)
);
INSERT assessment.GradebookEnrollment(SchoolId,GradebookId,EnrollmentId,StudentName,StudentCode) SELECT DISTINCT g.SchoolId,g.GradebookId,g.EnrollmentId,CONCAT(p.GivenName,N'' '',p.FamilyName),s.StudentNumber FROM assessment.GradeItem g JOIN people.StudentEnrollment e ON e.EnrollmentId=g.EnrollmentId JOIN people.StudentProfile s ON s.StudentId=e.StudentId JOIN people.Person p ON p.PersonId=s.PersonId;
ALTER TABLE assessment.GradeItem ADD CONSTRAINT FK_GradeItem_Roster FOREIGN KEY(SchoolId,GradebookId,EnrollmentId) REFERENCES assessment.GradebookEnrollment(SchoolId,GradebookId,EnrollmentId);
CREATE TABLE assessment.GradeItemRevision(
 GradeItemRevisionId uniqueidentifier NOT NULL CONSTRAINT DF_GradeItemRevision_Id DEFAULT NEWSEQUENTIALID(),SchoolId uniqueidentifier NOT NULL,GradebookId uniqueidentifier NOT NULL,EnrollmentId uniqueidentifier NOT NULL,GradingComponentId uniqueidentifier NOT NULL,Score decimal(9,4) NULL,DescriptiveLevel nvarchar(100) NULL,Feedback nvarchar(2000) NULL,ActionCode varchar(10) NOT NULL,ActorUserId uniqueidentifier NOT NULL,CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_GradeItemRevision_At DEFAULT SYSUTCDATETIME(),
 CONSTRAINT PK_GradeItemRevision PRIMARY KEY(GradeItemRevisionId),CONSTRAINT FK_GradeItemRevision_Book FOREIGN KEY(SchoolId,GradebookId) REFERENCES assessment.Gradebook(SchoolId,GradebookId),CONSTRAINT FK_GradeItemRevision_Enrollment FOREIGN KEY(SchoolId,EnrollmentId) REFERENCES people.StudentEnrollment(SchoolId,EnrollmentId),CONSTRAINT FK_GradeItemRevision_Component FOREIGN KEY(SchoolId,GradingComponentId) REFERENCES assessment.GradingComponent(SchoolId,GradingComponentId),CONSTRAINT FK_GradeItemRevision_Actor FOREIGN KEY(ActorUserId) REFERENCES security.UserAccount(UserId),CONSTRAINT CK_GradeItemRevision_Action CHECK(ActionCode IN(''saved'',''cleared''))
);
CREATE INDEX IX_GradeItemRevision_Book ON assessment.GradeItemRevision(SchoolId,GradebookId,CreatedAtUtc);
INSERT security.Permission(Code,Description) SELECT v.Code,v.Name FROM(VALUES(''grading.policies.prepare'',N''إعداد سياسات العلامات''),(''grading.policies.approve'',N''اعتماد سياسات العلامات''),(''grades.read.published'',N''قراءة العلامات المنشورة للطالب والأبناء''),(''certificates.issue'',N''إصدار الشهادات ونتائج التحقق''))v(Code,Name)WHERE NOT EXISTS(SELECT 1 FROM security.Permission p WHERE p.Code=v.Code);
INSERT security.RolePermission(RoleId,PermissionId)SELECT r.RoleId,p.PermissionId FROM(VALUES(''school_admin'',''grading.policies.prepare''),(''principal'',''grading.policies.approve''),(''principal'',''certificates.issue''),(''student'',''grades.read.published''),(''parent'',''grades.read.published''))v(RoleCode,PermissionCode)JOIN security.Role r ON r.Code=v.RoleCode JOIN security.Permission p ON p.Code=v.PermissionCode WHERE NOT EXISTS(SELECT 1 FROM security.RolePermission x WHERE x.RoleId=r.RoleId AND x.PermissionId=p.PermissionId);
GRANT SELECT,INSERT ON assessment.PolicyReview TO awn_backend;
GRANT SELECT,INSERT,UPDATE,DELETE ON assessment.GradingLevel TO awn_backend;
GRANT SELECT ON assessment.GradebookEnrollment TO awn_backend;
GRANT SELECT,INSERT ON assessment.GradeItemRevision TO awn_backend;
DENY UPDATE,DELETE ON assessment.PolicyReview TO awn_backend;
DENY UPDATE,DELETE ON assessment.GradeItemRevision TO awn_backend;';
 EXEC sys.sp_executesql N'
EXEC(N''CREATE OR ALTER TRIGGER assessment.TR_Policy_ApprovedFrozen ON assessment.GradingPolicy AFTER UPDATE,DELETE AS BEGIN SET NOCOUNT ON;
IF EXISTS(SELECT 1 FROM deleted d LEFT JOIN inserted i ON i.GradingPolicyId=d.GradingPolicyId WHERE d.Status<>''''draft'''' AND(i.GradingPolicyId IS NULL OR NOT(d.Status=i.Status OR(d.Status=''''approved'''' AND i.Status=''''retired'''')) OR EXISTS(SELECT d.SchoolId,d.SchoolYearId,d.TermId,d.StageId,d.GradeLevelId,d.SubjectId,d.Code,d.VersionNo,d.AssessmentMode,d.RoundingRule,d.TotalMaximum,d.Title,d.EffectiveFrom,d.EffectiveTo,d.CreatedByUserId EXCEPT SELECT i.SchoolId,i.SchoolYearId,i.TermId,i.StageId,i.GradeLevelId,i.SubjectId,i.Code,i.VersionNo,i.AssessmentMode,i.RoundingRule,i.TotalMaximum,i.Title,i.EffectiveFrom,i.EffectiveTo,i.CreatedByUserId))) THROW 52801,''''Approved policy content is immutable.'''',1;
IF EXISTS(SELECT 1 FROM inserted p WHERE p.Status=''''approved'''' AND(p.ReviewStatus<>''''approved'''' OR NOT EXISTS(SELECT 1 FROM assessment.GradingComponent c WHERE c.GradingPolicyId=p.GradingPolicyId) OR(p.AssessmentMode IN(''''descriptive'''',''''hybrid'''') AND(SELECT COUNT(*) FROM assessment.GradingLevel l WHERE l.GradingPolicyId=p.GradingPolicyId)<2) OR(p.AssessmentMode IN(''''weighted'''',''''hybrid'''') AND COALESCE((SELECT SUM(WeightPercent) FROM assessment.GradingComponent c WHERE c.GradingPolicyId=p.GradingPolicyId AND c.MaximumScore IS NOT NULL),-1)<>100))) THROW 52802,''''Approved policy needs valid components and levels.'''',1;
END;'');';
 EXEC sys.sp_executesql N'
EXEC(N''CREATE OR ALTER TRIGGER assessment.TR_GradingComponent_Frozen ON assessment.GradingComponent AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON;IF EXISTS(SELECT 1 FROM(SELECT SchoolId,GradingPolicyId FROM inserted UNION SELECT SchoolId,GradingPolicyId FROM deleted)x JOIN assessment.GradingPolicy p ON p.SchoolId=x.SchoolId AND p.GradingPolicyId=x.GradingPolicyId WHERE p.Status<>''''draft'''') THROW 52803,''''Approved policy components and levels are immutable.'''',1;END;'');';
 EXEC sys.sp_executesql N'
EXEC(N''CREATE OR ALTER TRIGGER assessment.TR_GradingLevel_Frozen ON assessment.GradingLevel AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON;IF EXISTS(SELECT 1 FROM(SELECT SchoolId,GradingPolicyId FROM inserted UNION SELECT SchoolId,GradingPolicyId FROM deleted)x JOIN assessment.GradingPolicy p ON p.SchoolId=x.SchoolId AND p.GradingPolicyId=x.GradingPolicyId WHERE p.Status<>''''draft'''') THROW 52803,''''Approved policy components and levels are immutable.'''',1;END;'');';
 EXEC sys.sp_executesql N'
EXEC(N''CREATE OR ALTER TRIGGER assessment.TR_PolicyReview_AppendOnly ON assessment.PolicyReview AFTER UPDATE,DELETE AS BEGIN SET NOCOUNT ON;IF EXISTS(SELECT 1 FROM deleted) THROW 52804,''''Grading history is append only.'''',1;END;'');';
 EXEC sys.sp_executesql N'
EXEC(N''CREATE OR ALTER TRIGGER assessment.TR_GradeItemRevision_AppendOnly ON assessment.GradeItemRevision AFTER UPDATE,DELETE AS BEGIN SET NOCOUNT ON;IF EXISTS(SELECT 1 FROM deleted) THROW 52804,''''Grading history is append only.'''',1;END;'');';
 EXEC sys.sp_executesql N'
EXEC(N''CREATE OR ALTER TRIGGER assessment.TR_GradeItem_Workflow ON assessment.GradeItem AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON;
IF EXISTS(SELECT 1 FROM(SELECT SchoolId,GradebookId FROM inserted UNION SELECT SchoolId,GradebookId FROM deleted)x JOIN assessment.Gradebook b ON b.SchoolId=x.SchoolId AND b.GradebookId=x.GradebookId WHERE b.Status NOT IN(''''draft'''',''''returned'''')) THROW 52805,''''Gradebook is not editable.'''',1;
IF EXISTS(SELECT 1 FROM inserted i JOIN assessment.GradingComponent c ON c.GradingComponentId=i.GradingComponentId WHERE(c.MaximumScore IS NOT NULL AND(i.Score IS NULL OR i.Score>c.MaximumScore OR i.DescriptiveLevel IS NOT NULL)) OR(c.MaximumScore IS NULL AND(i.Score IS NOT NULL OR NOT EXISTS(SELECT 1 FROM assessment.GradingLevel l WHERE l.SchoolId=i.SchoolId AND l.GradingPolicyId=c.GradingPolicyId AND l.Name=i.DescriptiveLevel)))) THROW 52806,''''Grade value does not match the policy component.'''',1;
INSERT assessment.GradeItemRevision(SchoolId,GradebookId,EnrollmentId,GradingComponentId,Score,DescriptiveLevel,Feedback,ActionCode,ActorUserId)
SELECT SchoolId,GradebookId,EnrollmentId,GradingComponentId,Score,DescriptiveLevel,Feedback,''''saved'''',UpdatedByUserId FROM inserted;
INSERT assessment.GradeItemRevision(SchoolId,GradebookId,EnrollmentId,GradingComponentId,Score,DescriptiveLevel,Feedback,ActionCode,ActorUserId)
SELECT d.SchoolId,d.GradebookId,d.EnrollmentId,d.GradingComponentId,d.Score,d.DescriptiveLevel,d.Feedback,''''cleared'''',COALESCE(TRY_CONVERT(uniqueidentifier,SESSION_CONTEXT(N''''Awn.GradingActor'''')),d.UpdatedByUserId) FROM deleted d WHERE NOT EXISTS(SELECT 1 FROM inserted i WHERE i.GradeItemId=d.GradeItemId);
END;'');';
 EXEC sys.sp_executesql N'
EXEC(N''CREATE OR ALTER TRIGGER assessment.TR_GradebookEnrollment_Frozen ON assessment.GradebookEnrollment AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON;
IF EXISTS(SELECT 1 FROM deleted) THROW 52807,''''Captured roster rows are immutable.'''',1;
IF EXISTS(SELECT 1 FROM inserted i JOIN assessment.Gradebook b ON b.SchoolId=i.SchoolId AND b.GradebookId=i.GradebookId JOIN academic.TeachingAssignment ta ON ta.TeachingAssignmentId=b.TeachingAssignmentId JOIN people.StudentEnrollment e ON e.EnrollmentId=i.EnrollmentId WHERE b.Status NOT IN(''''draft'''',''''returned'''') OR e.ClassSectionId<>ta.ClassSectionId OR e.SchoolYearId<>ta.SchoolYearId) THROW 52807,''''Roster must match the editable gradebook class and year.'''',1;
END;'');';
 EXEC sys.sp_executesql N'
EXEC(N''CREATE OR ALTER PROCEDURE assessment.CreateGradebook @SchoolId uniqueidentifier,@GradebookId uniqueidentifier,@TeachingAssignmentId uniqueidentifier,@GradingPolicyId uniqueidentifier,@ActorUserId uniqueidentifier AS BEGIN SET NOCOUNT ON;SET XACT_ABORT ON;
IF security.HasSchoolPermission(@ActorUserId,@SchoolId,''''grades.enter'''')=0 THROW 51603,''''Permission denied.'''',1;
IF NOT EXISTS(SELECT 1 FROM assessment.GradingPolicy WHERE SchoolId=@SchoolId AND GradingPolicyId=@GradingPolicyId AND Status=''''approved'''') THROW 51605,''''An approved policy is required.'''',1;
INSERT assessment.Gradebook(GradebookId,SchoolId,TeachingAssignmentId,GradingPolicyId,CreatedByUserId)VALUES(@GradebookId,@SchoolId,@TeachingAssignmentId,@GradingPolicyId,@ActorUserId);
END;'');';
 EXEC sys.sp_executesql N'
EXEC(N''CREATE OR ALTER PROCEDURE assessment.SyncGradebookRoster @SchoolId uniqueidentifier,@GradebookId uniqueidentifier,@ActorUserId uniqueidentifier AS BEGIN SET NOCOUNT ON;SET XACT_ABORT ON;
IF security.HasSchoolPermission(@ActorUserId,@SchoolId,''''grades.enter'''')=0 THROW 51603,''''Permission denied.'''',1;
IF NOT EXISTS(SELECT 1 FROM assessment.Gradebook WITH(UPDLOCK,HOLDLOCK) WHERE SchoolId=@SchoolId AND GradebookId=@GradebookId AND Status IN(''''draft'''',''''returned'''')) THROW 52805,''''Gradebook is not editable.'''',1;
INSERT assessment.GradebookEnrollment(SchoolId,GradebookId,EnrollmentId,StudentName,StudentCode)
SELECT @SchoolId,@GradebookId,e.EnrollmentId,CONCAT(p.GivenName,N'''' '''',p.FamilyName),s.StudentNumber FROM assessment.Gradebook b JOIN academic.TeachingAssignment ta ON ta.TeachingAssignmentId=b.TeachingAssignmentId JOIN core.AcademicTerm term ON term.TermId=ta.TermId JOIN people.StudentEnrollment e ON e.SchoolId=ta.SchoolId AND e.ClassSectionId=ta.ClassSectionId AND e.SchoolYearId=ta.SchoolYearId JOIN people.StudentProfile s ON s.StudentId=e.StudentId JOIN people.Person p ON p.PersonId=s.PersonId WHERE b.SchoolId=@SchoolId AND b.GradebookId=@GradebookId AND e.Status<>''''cancelled'''' AND e.StartDate<=term.EndDate AND COALESCE(e.EndDate,''''99991231'''')>=term.StartDate AND NOT EXISTS(SELECT 1 FROM assessment.GradebookEnrollment x JOIN people.StudentEnrollment xe ON xe.EnrollmentId=x.EnrollmentId WHERE x.SchoolId=@SchoolId AND x.GradebookId=@GradebookId AND xe.StudentId=e.StudentId)
AND NOT EXISTS(SELECT 1 FROM people.StudentEnrollment e2 WHERE e2.SchoolId=e.SchoolId AND e2.ClassSectionId=e.ClassSectionId AND e2.SchoolYearId=e.SchoolYearId AND e2.StudentId=e.StudentId AND e2.Status<>''''cancelled'''' AND e2.StartDate<=term.EndDate AND COALESCE(e2.EndDate,''''99991231'''')>=term.StartDate AND(e2.StartDate>e.StartDate OR(e2.StartDate=e.StartDate AND e2.EnrollmentId>e.EnrollmentId)));
END;'');';
 EXEC sys.sp_executesql N'
EXEC(N''CREATE OR ALTER PROCEDURE assessment.TouchGradebook @SchoolId uniqueidentifier,@GradebookId uniqueidentifier,@ActorUserId uniqueidentifier,@ExpectedRevision int AS BEGIN SET NOCOUNT ON;SET XACT_ABORT ON;
IF security.HasSchoolPermission(@ActorUserId,@SchoolId,''''grades.enter'''')=0 THROW 51603,''''Permission denied.'''',1;
IF @ExpectedRevision IS NULL OR NOT EXISTS(SELECT 1 FROM assessment.Gradebook WITH(UPDLOCK,HOLDLOCK) WHERE SchoolId=@SchoolId AND GradebookId=@GradebookId AND Revision=@ExpectedRevision AND Status IN(''''draft'''',''''returned'''')) THROW 51602,''''Gradebook not found or stale revision.'''',1;
UPDATE assessment.Gradebook SET Revision=Revision+1 WHERE SchoolId=@SchoolId AND GradebookId=@GradebookId;
END;'');';
 EXEC sys.sp_executesql N'
EXEC(N''CREATE OR ALTER PROCEDURE assessment.PublishGradebook @SchoolId uniqueidentifier,@GradebookId uniqueidentifier,@ActorUserId uniqueidentifier,@ExpectedRevision int AS BEGIN SET NOCOUNT ON;SET XACT_ABORT ON;
DECLARE @status varchar(20),@revision int,@policy uniqueidentifier,@mode varchar(20),@round varchar(20),@maximum decimal(9,4),@version int,@pub uniqueidentifier=NEWID(),@payload nvarchar(max);
BEGIN TRY BEGIN TRANSACTION;
SELECT @status=b.Status,@revision=b.Revision,@policy=b.GradingPolicyId,@mode=p.AssessmentMode,@round=p.RoundingRule,@maximum=p.TotalMaximum FROM assessment.Gradebook b WITH(UPDLOCK,HOLDLOCK) JOIN assessment.GradingPolicy p ON p.GradingPolicyId=b.GradingPolicyId WHERE b.SchoolId=@SchoolId AND b.GradebookId=@GradebookId AND p.Status IN(''''approved'''',''''retired'''');
IF @ExpectedRevision IS NULL OR @ExpectedRevision<=0 OR @status IS NULL OR @status<>''''approved'''' OR @ExpectedRevision<>@revision THROW 51606,''''Approved gradebook with current revision required.'''',1;
IF security.HasSchoolPermission(@ActorUserId,@SchoolId,''''grades.publish'''')=0 THROW 51603,''''Permission denied.'''',1;
IF NOT EXISTS(SELECT 1 FROM assessment.GradebookEnrollment WHERE SchoolId=@SchoolId AND GradebookId=@GradebookId) THROW 51609,''''No captured students.'''',1;
IF NOT EXISTS(SELECT 1 FROM assessment.GradingComponent WHERE GradingPolicyId=@policy) THROW 51607,''''Policy has no components.'''',1;
IF EXISTS(SELECT 1 FROM assessment.GradebookEnrollment e WITH(UPDLOCK,HOLDLOCK) CROSS JOIN assessment.GradingComponent c LEFT JOIN assessment.GradeItem g ON g.SchoolId=e.SchoolId AND g.GradebookId=e.GradebookId AND g.EnrollmentId=e.EnrollmentId AND g.GradingComponentId=c.GradingComponentId WHERE e.SchoolId=@SchoolId AND e.GradebookId=@GradebookId AND c.GradingPolicyId=@policy AND(c.IsRequired=1 OR c.MaximumScore IS NOT NULL) AND(g.GradeItemId IS NULL OR(c.MaximumScore IS NOT NULL AND g.Score IS NULL) OR(c.MaximumScore IS NULL AND g.DescriptiveLevel IS NULL))) THROW 51608,''''Required results are missing; missing numeric scores are never zero.'''',1;
IF @mode IN(''''weighted'''',''''hybrid'''') AND(SELECT SUM(WeightPercent) FROM assessment.GradingComponent WHERE GradingPolicyId=@policy AND MaximumScore IS NOT NULL)<>100 THROW 51613,''''Numeric weights must total 100.'''',1;
DECLARE @results table(EnrollmentId uniqueidentifier PRIMARY KEY,Score decimal(9,4),MaximumScore decimal(9,4),DescriptiveResult nvarchar(500),DetailsJson nvarchar(max));
INSERT @results SELECT e.EnrollmentId,CASE WHEN @mode=''''descriptive'''' THEN NULL ELSE SUM(g.Score/NULLIF(c.MaximumScore,0)*c.WeightPercent/100*@maximum) END,@maximum,CASE WHEN @mode IN(''''descriptive'''',''''hybrid'''') THEN N''''التقييم حسب المهارات المرفقة'''' ELSE NULL END,
(SELECT e.StudentName AS studentName,e.StudentCode AS studentCode,(SELECT c2.Code AS code,c2.Name AS name,c2.MaximumScore AS maximumScore,c2.WeightPercent AS weight,g2.Score AS score,g2.DescriptiveLevel AS level,g2.Feedback AS feedback FROM assessment.GradingComponent c2 LEFT JOIN assessment.GradeItem g2 ON g2.SchoolId=e.SchoolId AND g2.GradebookId=e.GradebookId AND g2.EnrollmentId=e.EnrollmentId AND g2.GradingComponentId=c2.GradingComponentId WHERE c2.GradingPolicyId=@policy ORDER BY c2.SortOrder,c2.Code FOR JSON PATH,INCLUDE_NULL_VALUES) AS components FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)
FROM assessment.GradebookEnrollment e CROSS JOIN assessment.GradingComponent c LEFT JOIN assessment.GradeItem g ON g.SchoolId=e.SchoolId AND g.GradebookId=e.GradebookId AND g.EnrollmentId=e.EnrollmentId AND g.GradingComponentId=c.GradingComponentId WHERE e.SchoolId=@SchoolId AND e.GradebookId=@GradebookId AND c.GradingPolicyId=@policy GROUP BY e.SchoolId,e.GradebookId,e.EnrollmentId,e.StudentName,e.StudentCode;
UPDATE @results SET Score=CASE @round WHEN ''''nearest'''' THEN ROUND(Score,0) WHEN ''''floor'''' THEN FLOOR(Score) WHEN ''''ceiling'''' THEN CEILING(Score) ELSE Score END;
SELECT @payload=(SELECT EnrollmentId,Score,MaximumScore,DescriptiveResult,DetailsJson FROM @results ORDER BY EnrollmentId FOR JSON PATH,INCLUDE_NULL_VALUES);
SELECT @version=COALESCE(MAX(VersionNo),0)+1 FROM assessment.GradePublication WITH(UPDLOCK,HOLDLOCK) WHERE SchoolId=@SchoolId AND GradebookId=@GradebookId;
INSERT assessment.GradePublication(GradePublicationId,SchoolId,GradebookId,VersionNo,SnapshotHash,PublishedByUserId)VALUES(@pub,@SchoolId,@GradebookId,@version,HASHBYTES(''''SHA2_256'''',@payload),@ActorUserId);
INSERT assessment.PublishedGrade(SchoolId,GradePublicationId,EnrollmentId,Score,MaximumScore,DescriptiveResult,DetailsJson)SELECT @SchoolId,@pub,EnrollmentId,Score,MaximumScore,DescriptiveResult,DetailsJson FROM @results;
UPDATE assessment.GradePublication SET SealedAtUtc=SYSUTCDATETIME() WHERE GradePublicationId=@pub;
UPDATE assessment.Gradebook SET Status=''''locked'''',LockedAtUtc=SYSUTCDATETIME(),Revision=Revision+1 WHERE GradebookId=@GradebookId;
INSERT assessment.GradebookWorkflowEvent(SchoolId,GradebookId,ActorUserId,FromStatus,ToStatus,Revision)VALUES(@SchoolId,@GradebookId,@ActorUserId,''''approved'''',''''locked'''',@revision+1);
COMMIT;SELECT @pub AS id,@version AS version;
END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK;THROW;END CATCH;END;'');';
 EXEC sys.sp_executesql N'
EXEC(N''CREATE OR ALTER PROCEDURE assessment.TransitionGradebook
 @SchoolId uniqueidentifier,@GradebookId uniqueidentifier,@ActorUserId uniqueidentifier,@ExpectedRevision int,@ToStatus varchar(20),@Note nvarchar(2000)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @from varchar(20),@revision int,@permission varchar(120);
 BEGIN TRY
  BEGIN TRANSACTION;
  SELECT @from=Status,@revision=Revision FROM assessment.Gradebook WITH(UPDLOCK,HOLDLOCK) WHERE SchoolId=@SchoolId AND GradebookId=@GradebookId;
  IF @ExpectedRevision IS NULL OR @ExpectedRevision<=0 OR @from IS NULL OR @revision<>@ExpectedRevision THROW 51602,''''Gradebook not found or stale revision.'''',1;
  SET @permission=CASE WHEN @ToStatus=''''submitted'''' THEN ''''grades.enter'''' WHEN @ToStatus IN (''''reviewed'''',''''returned'''') THEN ''''grades.review'''' WHEN @ToStatus=''''approved'''' THEN ''''grades.publish'''' END;
  IF @permission IS NULL OR security.HasSchoolPermission(@ActorUserId,@SchoolId,@permission)=0 THROW 51603,''''Permission denied.'''',1;
  IF NOT ((@from IN (''''draft'''',''''returned'''') AND @ToStatus=''''submitted'''') OR (@from=''''submitted'''' AND @ToStatus IN (''''reviewed'''',''''returned'''')) OR (@from=''''reviewed'''' AND @ToStatus IN (''''approved'''',''''returned''''))) THROW 51604,''''Invalid gradebook transition.'''',1;
  IF NOT EXISTS(SELECT 1 FROM assessment.Gradebook b JOIN assessment.GradingPolicy p ON p.GradingPolicyId=b.GradingPolicyId WHERE b.GradebookId=@GradebookId AND p.Status IN(''''approved'''',''''retired'''')) THROW 51605,''''An approved policy is required.'''',1;
  UPDATE assessment.Gradebook SET Status=@ToStatus,Revision=Revision+1 WHERE GradebookId=@GradebookId;
  INSERT assessment.GradebookWorkflowEvent(SchoolId,GradebookId,ActorUserId,FromStatus,ToStatus,Note,Revision) VALUES(@SchoolId,@GradebookId,@ActorUserId,@from,@ToStatus,@Note,@revision+1);
  COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;'');';
 EXEC sys.sp_executesql N'
GRANT EXECUTE ON assessment.CreateGradebook TO awn_backend;
GRANT EXECUTE ON assessment.SyncGradebookRoster TO awn_backend;
GRANT EXECUTE ON assessment.TouchGradebook TO awn_backend;
';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(28,N''028_grading_workflows.sql'',0xe29dd305b8338ccea448a8a96f454e88febcd5c3f5ce33b4ea2fcba7b4263991,''executed'');';
 -- BEGIN 029_behavior_workflows.sql
 EXEC sys.sp_executesql N'SET NOCOUNT ON;
SET XACT_ABORT ON;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(''operations.BehaviorCategory'') AND name = ''Status'')
BEGIN
    ALTER TABLE operations.BehaviorCategory 
    ADD Status varchar(20) NOT NULL CONSTRAINT DF_BehaviorCategory_Status DEFAULT (''active'') 
    CONSTRAINT CK_BehaviorCategory_Status CHECK (Status IN (''active'', ''inactive''));
END;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(''operations.BehaviorCategory'') AND name = ''CreatedAtUtc'')
BEGIN
    ALTER TABLE operations.BehaviorCategory 
    ADD CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_BehaviorCategory_Created DEFAULT SYSUTCDATETIME();
END;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(''operations.BehaviorEntry'') AND name = ''CreatedAtUtc'')
BEGIN
    ALTER TABLE operations.BehaviorEntry 
    ADD CreatedAtUtc datetime2(3) NOT NULL CONSTRAINT DF_BehaviorEntry_Created DEFAULT SYSUTCDATETIME();
END;
';
 EXEC sys.sp_executesql N'
INSERT operations.BehaviorCategory (SchoolId, Code, Name, DefaultPoints, Status)
SELECT s.SchoolId, c.Code, c.Name, c.DefaultPoints, ''active''
FROM core.School s
CROSS JOIN (
    VALUES 
        (''merit_academic'', N''تفوق ومشاركة أكاديمية متميزة'', 5),
        (''merit_initiative'', N''مبادرة ومسؤولية تطوعية'', 3),
        (''merit_discipline'', N''انضباط وسلوك قيادي متميز'', 4),
        (''merit_cooperation'', N''تعاون ومساعدة الزملاء'', 3),
        (''demerit_tardiness'', N''تأخر صباحي متكرر بدون عذر'', -2),
        (''demerit_disruption'', N''تشويش وإخلال بالنظام الصفي'', -3),
        (''demerit_neglect'', N''إهمال تسليم الواجبات والأنشطة'', -2),
        (''demerit_inappropriate'', N''سلوك غير لائق أو مخالف للآداب'', -5)
) AS c(Code, Name, DefaultPoints)
WHERE NOT EXISTS (
    SELECT 1 FROM operations.BehaviorCategory existing 
    WHERE existing.SchoolId = s.SchoolId AND existing.Code = c.Code
);

INSERT security.Permission (Code, Description)
SELECT v.Code, v.Name
FROM (
    VALUES
        (''behavior.read'', N''عرض سجلات وملاحظات السلوك''),
        (''behavior.manage'', N''تسجيل وعكس نقاط وملاحظات السلوك''),
        (''incidents.read'', N''عرض سجلات الحوادث والمخالفات الحرجة''),
        (''incidents.manage'', N''تسجيل ومتابعة وإغلاق الحوادث المدرسية'')
) AS v(Code, Name)
WHERE NOT EXISTS (SELECT 1 FROM security.Permission p WHERE p.Code = v.Code);

INSERT security.RolePermission (RoleId, PermissionId)
SELECT r.RoleId, p.PermissionId
FROM (
    VALUES
        (''admin'', ''behavior.read''),
        (''admin'', ''behavior.manage''),
        (''admin'', ''incidents.read''),
        (''admin'', ''incidents.manage''),
        (''principal'', ''behavior.read''),
        (''principal'', ''behavior.manage''),
        (''principal'', ''incidents.read''),
        (''principal'', ''incidents.manage''),
        (''school_admin'', ''behavior.read''),
        (''school_admin'', ''behavior.manage''),
        (''teacher'', ''behavior.read''),
        (''teacher'', ''behavior.manage''),
        (''supervisor'', ''behavior.read''),
        (''supervisor'', ''incidents.read''),
        (''student'', ''behavior.read''),
        (''parent'', ''behavior.read'')
) AS v(RoleCode, PermissionCode)
JOIN security.Role r ON r.Code = v.RoleCode
JOIN security.Permission p ON p.Code = v.PermissionCode
WHERE NOT EXISTS (
    SELECT 1 FROM security.RolePermission x 
    WHERE x.RoleId = r.RoleId AND x.PermissionId = p.PermissionId
);

GRANT SELECT, INSERT, UPDATE ON operations.BehaviorCategory TO awn_backend;
GRANT SELECT, INSERT ON operations.BehaviorEntry TO awn_backend;
GRANT SELECT, INSERT, UPDATE ON operations.Incident TO awn_backend;
GRANT SELECT, INSERT, UPDATE, DELETE ON operations.IncidentParty TO awn_backend;

DENY UPDATE, DELETE ON operations.BehaviorEntry TO awn_backend;
';
 EXEC sys.sp_executesql N'
EXEC(N''CREATE OR ALTER TRIGGER operations.TR_Incident_Workflow ON operations.Incident AFTER UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        THROW 52901, ''''Incidents cannot be deleted. Use status closed or follow-up.'''', 1;
    END;

    IF EXISTS (
        SELECT 1 FROM deleted d 
        JOIN inserted i ON i.IncidentId = d.IncidentId
        WHERE d.Status = ''''closed'''' AND i.Status = ''''closed''''
        AND EXISTS (
            SELECT d.SchoolId, d.OccurredAtUtc, d.CategoryCode, d.Severity, d.Summary, d.Confidentiality, d.ReportedByUserId
            EXCEPT
            SELECT i.SchoolId, i.OccurredAtUtc, i.CategoryCode, i.Severity, i.Summary, i.Confidentiality, i.ReportedByUserId
        )
    )
    BEGIN
        THROW 52902, ''''Closed incidents cannot have their summary or incident details modified.'''', 1;
    END;
END;'');
';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(29,N''029_behavior_workflows.sql'',0x06a1a10ee6cb4fca8eb58583fa8613c6ef28a4311d0a3904441d303e26b361fb,''executed'');';
 -- BEGIN 030_communication_workflows.sql
 EXEC sys.sp_executesql N'SET NOCOUNT ON;
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;

INSERT security.Permission (Code, Description)
SELECT v.Code, v.Name
FROM (
    VALUES
        (''circulars.read'', N''عرض وتأكيد قراءة التعاميم المدرسية''),
        (''circulars.manage'', N''إعداد ونشر وأرشفة التعاميم المدرسية''),
        (''appointments.request'', N''حجز ومتابعة وإلغاء مواعيد لقاء الكادر''),
        (''appointments.manage'', N''إدارة الساعات المكتبية ومواعيد اللقاء'')
) AS v(Code, Name)
WHERE NOT EXISTS (SELECT 1 FROM security.Permission p WHERE p.Code = v.Code);

INSERT security.RolePermission (RoleId, PermissionId)
SELECT r.RoleId, p.PermissionId
FROM (
    VALUES
        (''admin'', ''circulars.read''),
        (''admin'', ''circulars.manage''),
        (''admin'', ''appointments.request''),
        (''admin'', ''appointments.manage''),
        (''principal'', ''circulars.read''),
        (''principal'', ''circulars.manage''),
        (''principal'', ''appointments.request''),
        (''principal'', ''appointments.manage''),
        (''school_admin'', ''circulars.read''),
        (''school_admin'', ''circulars.manage''),
        (''teacher'', ''circulars.read''),
        (''teacher'', ''appointments.manage''),
        (''supervisor'', ''circulars.read''),
        (''parent'', ''circulars.read''),
        (''parent'', ''appointments.request''),
        (''student'', ''circulars.read'')
) AS v(RoleCode, PermissionCode)
JOIN security.Role r ON r.Code = v.RoleCode
JOIN security.Permission p ON p.Code = v.PermissionCode
WHERE NOT EXISTS (
    SELECT 1 FROM security.RolePermission x 
    WHERE x.RoleId = r.RoleId AND x.PermissionId = p.PermissionId
);

GRANT SELECT, INSERT, UPDATE, DELETE ON learning.Circular TO awn_backend;
GRANT SELECT, INSERT, UPDATE, DELETE ON learning.CircularAudience TO awn_backend;
GRANT SELECT, INSERT ON learning.CircularAcknowledgement TO awn_backend;
GRANT SELECT, INSERT, UPDATE ON learning.Conversation TO awn_backend;
GRANT SELECT, INSERT, UPDATE ON learning.ConversationMember TO awn_backend;
GRANT SELECT, INSERT ON learning.Message TO awn_backend;
GRANT SELECT, INSERT, UPDATE ON operations.OfficeHourSlot TO awn_backend;
GRANT SELECT, INSERT, UPDATE ON operations.Appointment TO awn_backend;

DENY UPDATE, DELETE ON learning.CircularAcknowledgement TO awn_backend;
DENY UPDATE, DELETE ON learning.Message TO awn_backend;
';
 EXEC sys.sp_executesql N'
EXEC(N''CREATE OR ALTER TRIGGER learning.TR_Circular_ImmutablePublished ON learning.Circular AFTER UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM deleted d 
        JOIN inserted i ON i.CircularId = d.CircularId
        WHERE d.Status = ''''published'''' AND i.Status = ''''published''''
        AND EXISTS (
            SELECT d.Title, d.Body, d.CreatedByUserId, d.PublishedAtUtc
            EXCEPT
            SELECT i.Title, i.Body, i.CreatedByUserId, i.PublishedAtUtc
        )
    )
    BEGIN
        THROW 53001, ''''Published circular content is immutable. Create a new revision.'''', 1;
    END;
END;'');
';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(30,N''030_communication_workflows.sql'',0x04b1127b05d4ad3b6db2e41a0d96b104704d48ee352a95c6a69eba0c1d91c011,''executed'');';
 -- BEGIN 031_payroll_workflows.sql
 EXEC sys.sp_executesql N'SET XACT_ABORT ON;
SET NOCOUNT ON;

-- 1. Register Permissions
IF NOT EXISTS (SELECT 1 FROM security.Permission WHERE Code = ''contracts.read'')
    INSERT security.Permission (Code, Description)
    VALUES (''contracts.read'', N''استعراض عقود العمل وبنود الرواتب للكادر التعليمي والإداري'');

IF NOT EXISTS (SELECT 1 FROM security.Permission WHERE Code = ''contracts.manage'')
    INSERT security.Permission (Code, Description)
    VALUES (''contracts.manage'', N''إدارة وتوثيق وتعديل عقود العمل وبنود استحقاق واستقطاع الرواتب'');

-- 2. Map Permissions in security.RolePermission
INSERT security.RolePermission (RoleId, PermissionId)
SELECT r.RoleId, p.PermissionId
FROM security.Role r
CROSS JOIN security.Permission p
WHERE (
    (r.Code = ''payroll_officer'' AND p.Code IN (''payroll.read'', ''payroll.manage'', ''contracts.read'')) OR
    (r.Code = ''hr_officer'' AND p.Code IN (''contracts.read'', ''contracts.manage'', ''payroll.read'')) OR
    (r.Code = ''principal'' AND p.Code IN (''contracts.read'', ''contracts.manage'', ''payroll.read'', ''payroll.manage'')) OR
    (r.Code = ''admin'' AND p.Code IN (''contracts.read'', ''contracts.manage'', ''payroll.read'', ''payroll.manage'')) OR
    (r.Code = ''school_admin'' AND p.Code IN (''contracts.read'', ''payroll.read''))
)
AND NOT EXISTS (
    SELECT 1 FROM security.RolePermission rp
    WHERE rp.RoleId = r.RoleId AND rp.PermissionId = p.PermissionId
);
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER PROCEDURE hr.CreatePayrollRun
    @SchoolId uniqueidentifier,
    @PeriodStart date,
    @PeriodEnd date,
    @RunNo smallint,
    @CurrencyCode char(3),
    @ActorUserId uniqueidentifier,
    @PayrollRunId uniqueidentifier OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF security.HasSchoolPermission(@ActorUserId, @SchoolId, ''payroll.manage'') = 0
            THROW 52406, ''Payroll permission required.'', 1;

        IF @PeriodStart > @PeriodEnd
            THROW 53100, ''Invalid period dates: PeriodStart cannot exceed PeriodEnd.'', 1;

        IF @PayrollRunId IS NULL
            SET @PayrollRunId = NEWID();

        INSERT hr.PayrollRun (PayrollRunId, SchoolId, PeriodStart, PeriodEnd, RunNo, CurrencyCode, Status, CreatedAtUtc)
        VALUES (@PayrollRunId, @SchoolId, @PeriodStart, @PeriodEnd, @RunNo, UPPER(@CurrencyCode), ''draft'', SYSUTCDATETIME());

        INSERT audit.AuditEvent(OrganizationId, SchoolId, ActorUserId, ActionCode, EntityType, EntityId, Outcome)
        SELECT OrganizationId, @SchoolId, @ActorUserId, ''payroll.run.created'', ''hr.PayrollRun'', CONVERT(nvarchar(36), @PayrollRunId), ''success''
        FROM core.School WHERE SchoolId = @SchoolId;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH;
END;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER PROCEDURE hr.SubmitPayrollRun
    @SchoolId uniqueidentifier,
    @PayrollRunId uniqueidentifier,
    @ActorUserId uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF security.HasSchoolPermission(@ActorUserId, @SchoolId, ''payroll.manage'') = 0
            THROW 52406, ''Payroll permission required.'', 1;

        IF NOT EXISTS (
            SELECT 1 FROM hr.PayrollRun WITH (UPDLOCK, HOLDLOCK)
            WHERE SchoolId = @SchoolId AND PayrollRunId = @PayrollRunId AND Status IN (''draft'', ''calculated'')
        )
            THROW 53101, ''Payroll run must be in draft or calculated status to submit.'', 1;

        IF NOT EXISTS (
            SELECT 1 FROM hr.PayrollRunLine WITH (UPDLOCK, HOLDLOCK)
            WHERE SchoolId = @SchoolId AND PayrollRunId = @PayrollRunId
        )
            THROW 52408, ''Payroll has no lines.'', 1;

        UPDATE hr.PayrollRun
        SET Status = ''submitted''
        WHERE SchoolId = @SchoolId AND PayrollRunId = @PayrollRunId;

        INSERT audit.AuditEvent(OrganizationId, SchoolId, ActorUserId, ActionCode, EntityType, EntityId, Outcome)
        SELECT OrganizationId, @SchoolId, @ActorUserId, ''payroll.run.submitted'', ''hr.PayrollRun'', CONVERT(nvarchar(36), @PayrollRunId), ''success''
        FROM core.School WHERE SchoolId = @SchoolId;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH;
END;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER PROCEDURE hr.CancelPayrollRun
    @SchoolId uniqueidentifier,
    @PayrollRunId uniqueidentifier,
    @ActorUserId uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF security.HasSchoolPermission(@ActorUserId, @SchoolId, ''payroll.manage'') = 0
            THROW 52406, ''Payroll permission required.'', 1;

        IF NOT EXISTS (
            SELECT 1 FROM hr.PayrollRun WITH (UPDLOCK, HOLDLOCK)
            WHERE SchoolId = @SchoolId AND PayrollRunId = @PayrollRunId AND Status IN (''draft'', ''calculated'', ''submitted'')
        )
            THROW 53102, ''Cannot cancel an approved or paid payroll run.'', 1;

        UPDATE hr.PayrollRun
        SET Status = ''cancelled''
        WHERE SchoolId = @SchoolId AND PayrollRunId = @PayrollRunId;

        INSERT audit.AuditEvent(OrganizationId, SchoolId, ActorUserId, ActionCode, EntityType, EntityId, Outcome)
        SELECT OrganizationId, @SchoolId, @ActorUserId, ''payroll.run.cancelled'', ''hr.PayrollRun'', CONVERT(nvarchar(36), @PayrollRunId), ''success''
        FROM core.School WHERE SchoolId = @SchoolId;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH;
END;
';
 EXEC sys.sp_executesql N'
INSERT hr.SalaryComponent (SalaryComponentId, SchoolId, Code, Name, ComponentType)
SELECT NEWID(), s.SchoolId, c.Code, c.Name, c.ComponentType
FROM core.School s
CROSS JOIN (
    VALUES
        (''basic'', N''الراتب الأساسي'', ''earning''),
        (''housing'', N''علاوة بدل سكن'', ''earning''),
        (''transport'', N''علاوة بدل مواصلات وانتقال'', ''earning''),
        (''social_security'', N''اقتطاع الضمان الاجتماعي'', ''deduction''),
        (''health_insurance'', N''اقتطاع التأمين الصحي'', ''deduction''),
        (''income_tax'', N''اقتطاع ضريبة الدخل'', ''deduction'')
) AS c(Code, Name, ComponentType)
WHERE NOT EXISTS (
    SELECT 1 FROM hr.SalaryComponent sc
    WHERE sc.SchoolId = s.SchoolId AND sc.Code = c.Code
);
';
 EXEC sys.sp_executesql N'
GRANT SELECT, INSERT, UPDATE, DELETE ON hr.EmploymentContract TO awn_backend;
GRANT SELECT, INSERT, UPDATE, DELETE ON hr.SalaryComponent TO awn_backend;
GRANT SELECT, INSERT, UPDATE, DELETE ON hr.EmployeeSalaryComponent TO awn_backend;
GRANT SELECT, INSERT, UPDATE, DELETE ON hr.PayrollRunLine TO awn_backend;
GRANT SELECT ON hr.PayrollRun TO awn_backend;
GRANT EXECUTE ON hr.CreatePayrollRun TO awn_backend;
GRANT EXECUTE ON hr.SubmitPayrollRun TO awn_backend;
GRANT EXECUTE ON hr.CancelPayrollRun TO awn_backend;
';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(31,N''031_payroll_workflows.sql'',0x73d05a075db226be35f9622e053f6a34a3348d7bfaae7b77458bd9d7fec887fd,''executed'');';
 -- BEGIN 032_admissions_workflows.sql
 EXEC sys.sp_executesql N'SET XACT_ABORT ON;
SET NOCOUNT ON;

-- 1. Register Permissions
IF NOT EXISTS (SELECT 1 FROM security.Permission WHERE Code = ''admissions.read'')
    INSERT security.Permission (Code, Description)
    VALUES (''admissions.read'', N''استعراض طلبات القبول والتسجيل المدرسية وقرارات اللجان'');

IF NOT EXISTS (SELECT 1 FROM security.Permission WHERE Code = ''admissions.manage'')
    INSERT security.Permission (Code, Description)
    VALUES (''admissions.manage'', N''إدارة وتقديم ودراسة واتخاذ قرارات القبول والتسجيل للطلبة الجدد'');

IF NOT EXISTS (SELECT 1 FROM security.Permission WHERE Code = ''visitors.read'')
    INSERT security.Permission (Code, Description)
    VALUES (''visitors.read'', N''استعراض سجل الزوار والاستقبال وحركات الدخول والمغادرة'');

IF NOT EXISTS (SELECT 1 FROM security.Permission WHERE Code = ''visitors.manage'')
    INSERT security.Permission (Code, Description)
    VALUES (''visitors.manage'', N''تسجيل زيارات الاستقبال وتحديد الموظف المضيف وتوثيق المغادرة'');

-- 2. Map Permissions in security.RolePermission
INSERT security.RolePermission (RoleId, PermissionId)
SELECT r.RoleId, p.PermissionId
FROM security.Role r
CROSS JOIN security.Permission p
WHERE (
    (r.Code = ''admissions_officer'' AND p.Code IN (''admissions.read'', ''admissions.manage'', ''visitors.read'')) OR
    (r.Code = ''receptionist'' AND p.Code IN (''visitors.read'', ''visitors.manage'', ''admissions.read'', ''appointments.manage'')) OR
    (r.Code = ''principal'' AND p.Code IN (''admissions.read'', ''admissions.manage'', ''visitors.read'', ''visitors.manage'')) OR
    (r.Code = ''admin'' AND p.Code IN (''admissions.read'', ''admissions.manage'', ''visitors.read'', ''visitors.manage'')) OR
    (r.Code = ''school_admin'' AND p.Code IN (''admissions.read'', ''visitors.read''))
)
AND NOT EXISTS (
    SELECT 1 FROM security.RolePermission rp
    WHERE rp.RoleId = r.RoleId AND rp.PermissionId = p.PermissionId
);
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER TRIGGER admissions.TR_ApplicationDecision_Workflow
ON admissions.ApplicationDecision
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Invariant: Cannot record a decision on an application that is already enrolled or withdrawn
    IF EXISTS (
        SELECT 1 
        FROM admissions.Application a WITH (UPDLOCK, HOLDLOCK)
        JOIN inserted i ON i.ApplicationId = a.ApplicationId
        WHERE a.Status IN (''enrolled'', ''withdrawn'')
    )
        THROW 53200, ''Cannot record a new decision on an application that is already enrolled or withdrawn.'', 1;

    -- Invariant: DecidedByUserId cannot be empty and decision reason must be provided for rejected/waitlisted
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        WHERE i.Decision IN (''rejected'', ''waitlisted'') AND (i.Reason IS NULL OR LEN(LTRIM(RTRIM(i.Reason))) = 0)
    )
        THROW 53203, ''A clear reason must be documented when rejecting or waitlisting an application.'', 1;

    -- Update Application Status to match the Decision
    UPDATE a
    SET a.Status = i.Decision
    FROM admissions.Application a
    JOIN inserted i ON i.ApplicationId = a.ApplicationId;
END;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER TRIGGER operations.TR_VisitorLog_Integrity
ON operations.VisitorLog
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Invariant: HostEmployee must be an active employee in the same school
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        LEFT JOIN people.EmployeeProfile emp ON emp.SchoolId = i.SchoolId AND emp.EmployeeId = i.HostEmployeeId
        WHERE emp.EmployeeId IS NULL OR emp.EmploymentStatus <> ''active''
    )
        THROW 53201, ''Host employee must be an active employee in the same school.'', 1;

    -- Invariant: DepartedAtUtc cannot precede ArrivedAtUtc
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        WHERE i.DepartedAtUtc IS NOT NULL AND i.DepartedAtUtc < i.ArrivedAtUtc
    )
        THROW 53202, ''Departure time cannot precede arrival time.'', 1;
END;
';
 EXEC sys.sp_executesql N'
GRANT SELECT, INSERT, UPDATE, DELETE ON admissions.Application TO awn_backend;
GRANT SELECT, INSERT, UPDATE, DELETE ON admissions.ApplicationDecision TO awn_backend;
GRANT SELECT, INSERT, UPDATE, DELETE ON operations.VisitorLog TO awn_backend;
';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(32,N''032_admissions_workflows.sql'',0x2ca9c6111cadad962ad286a6fa10821d8b8f628ddda0b46126aa26937169ced2,''executed'');';
 -- BEGIN 033_transport_workflows.sql
 EXEC sys.sp_executesql N'SET XACT_ABORT ON;
SET NOCOUNT ON;

-- 1. Register Permissions
IF NOT EXISTS (SELECT 1 FROM security.Permission WHERE Code = ''transport.read'')
    INSERT security.Permission (Code, Description)
    VALUES (''transport.read'', N''استعراض مسارات وحافلات النقل المدرسي ومواعيد الرحلات وحالة الركوب'');

IF NOT EXISTS (SELECT 1 FROM security.Permission WHERE Code = ''transport.manage'')
    INSERT security.Permission (Code, Description)
    VALUES (''transport.manage'', N''إدارة أسطول الحافلات والمسارات والمحطات وجدولة الرحلات وتسجيل ركوب ونزول الطلبة'');

-- 2. Map Permissions in security.RolePermission
INSERT security.RolePermission (RoleId, PermissionId)
SELECT r.RoleId, p.PermissionId
FROM security.Role r
CROSS JOIN security.Permission p
WHERE (
    (r.Code = ''transport_officer'' AND p.Code IN (''transport.read'', ''transport.manage'')) OR
    (r.Code = ''principal'' AND p.Code IN (''transport.read'', ''transport.manage'')) OR
    (r.Code = ''admin'' AND p.Code IN (''transport.read'', ''transport.manage'')) OR
    (r.Code = ''school_admin'' AND p.Code IN (''transport.read'')) OR
    (r.Code = ''parent'' AND p.Code IN (''transport.read'')) OR
    (r.Code = ''teacher'' AND p.Code IN (''transport.read''))
)
AND NOT EXISTS (
    SELECT 1 FROM security.RolePermission rp
    WHERE rp.RoleId = r.RoleId AND rp.PermissionId = p.PermissionId
);
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER TRIGGER transport.TR_RouteRun_Workflow
ON transport.RouteRun
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Invariant: If vehicle assigned, vehicle must be active and belong to same school
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        JOIN transport.Vehicle v ON v.SchoolId = i.SchoolId AND v.VehicleId = i.VehicleId
        WHERE v.Status = ''retired''
    )
        THROW 53300, ''Cannot assign a retired vehicle to a route run.'', 1;

    -- Invariant: If driver assigned, driver must be an active employee in same school
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        LEFT JOIN people.EmployeeProfile emp ON emp.SchoolId = i.SchoolId AND emp.EmployeeId = i.DriverEmployeeId
        WHERE i.DriverEmployeeId IS NOT NULL AND (emp.EmployeeId IS NULL OR emp.EmploymentStatus <> ''active'')
    )
        THROW 53301, ''Assigned driver must be an active employee in the same school.'', 1;

    -- Invariant: Completed run must have StartedAtUtc and CompletedAtUtc
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        WHERE i.Status = ''completed'' AND (i.StartedAtUtc IS NULL OR i.CompletedAtUtc IS NULL)
    )
        THROW 53302, ''Completed route run must have recorded start and completion timestamps.'', 1;
END;
';
 EXEC sys.sp_executesql N'
GRANT SELECT, INSERT, UPDATE, DELETE ON transport.Vehicle TO awn_backend;
GRANT SELECT, INSERT, UPDATE, DELETE ON transport.Route TO awn_backend;
GRANT SELECT, INSERT, UPDATE, DELETE ON transport.RouteStop TO awn_backend;
GRANT SELECT, INSERT, UPDATE, DELETE ON transport.RouteRun TO awn_backend;
GRANT SELECT, INSERT, UPDATE, DELETE ON transport.StudentRide TO awn_backend;
GRANT SELECT, INSERT, UPDATE, DELETE ON transport.TransportEnrollment TO awn_backend;
GRANT SELECT, INSERT, UPDATE, DELETE ON transport.RideNotice TO awn_backend;
GRANT SELECT, INSERT, UPDATE, DELETE ON transport.RunChaperone TO awn_backend;
GRANT SELECT, INSERT, UPDATE, DELETE ON transport.VehicleMaintenance TO awn_backend;
GRANT SELECT, INSERT, UPDATE, DELETE ON transport.VehicleDocument TO awn_backend;
';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(33,N''033_transport_workflows.sql'',0x9ddcfb3c7f44472de9042caa886e50809938e9d4a4b3c20cfcae103c974064a4,''executed'');';
 -- BEGIN 034_clinic_workflows.sql
 EXEC sys.sp_executesql N'SET XACT_ABORT ON;
SET NOCOUNT ON;

-- 1. Ensure / Register Permissions
IF NOT EXISTS (SELECT 1 FROM security.Permission WHERE Code = ''clinic.read'')
    INSERT security.Permission (Code, Description)
    VALUES (''clinic.read'', N''استعراض السجلات الطبية والملفات الصحية للطلبة وزيارات العيادة'');
ELSE
    UPDATE security.Permission
    SET Description = N''استعراض السجلات الطبية والملفات الصحية للطلبة وزيارات العيادة''
    WHERE Code = ''clinic.read'';

IF NOT EXISTS (SELECT 1 FROM security.Permission WHERE Code = ''clinic.manage'')
    INSERT security.Permission (Code, Description)
    VALUES (''clinic.manage'', N''تسجيل زيارات العيادة وتحديث الملفات الطبية وخطة الطوارئ الصحية'');
ELSE
    UPDATE security.Permission
    SET Description = N''تسجيل زيارات العيادة وتحديث الملفات الطبية وخطة الطوارئ الصحية''
    WHERE Code = ''clinic.manage'';

-- 2. Map Permissions in security.RolePermission
INSERT security.RolePermission (RoleId, PermissionId)
SELECT r.RoleId, p.PermissionId
FROM security.Role r
CROSS JOIN security.Permission p
WHERE (
    (r.Code = ''clinic_staff'' AND p.Code IN (''clinic.read'', ''clinic.manage'')) OR
    (r.Code = ''principal'' AND p.Code IN (''clinic.read'', ''clinic.manage'')) OR
    (r.Code = ''admin'' AND p.Code IN (''clinic.read'', ''clinic.manage'')) OR
    (r.Code = ''school_admin'' AND p.Code IN (''clinic.read''))
)
AND NOT EXISTS (
    SELECT 1 FROM security.RolePermission rp
    WHERE rp.RoleId = r.RoleId AND rp.PermissionId = p.PermissionId
);
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER TRIGGER health.TR_ClinicEncounter_Workflow
ON health.ClinicEncounter
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Invariant: Student must belong to the school
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        LEFT JOIN people.StudentProfile sp ON sp.SchoolId = i.SchoolId AND sp.StudentId = i.StudentId
        WHERE sp.StudentId IS NULL
    )
        THROW 53400, ''Student does not belong to the school.'', 1;

    -- Invariant: Encounter occurrence cannot be in the future (allowing small clock drift up to 15 mins)
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        WHERE i.OccurredAtUtc > DATEADD(minute, 15, SYSUTCDATETIME())
    )
        THROW 53401, ''Clinic encounter occurrence cannot be in the future.'', 1;

    -- Invariant: Must record at least symptoms, assessment, or action taken
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        WHERE NULLIF(LTRIM(RTRIM(i.Symptoms)), '''') IS NULL
          AND NULLIF(LTRIM(RTRIM(i.Assessment)), '''') IS NULL
          AND NULLIF(LTRIM(RTRIM(i.ActionTaken)), '''') IS NULL
    )
        THROW 53402, ''Encounter must record at least symptoms, assessment, or action taken.'', 1;
END;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER TRIGGER health.TR_StudentMedicalProfile_Workflow
ON health.StudentMedicalProfile
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Invariant: Emergency contact is mandatory
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        WHERE NULLIF(LTRIM(RTRIM(i.EmergencyContact)), '''') IS NULL
    )
        THROW 53403, ''Emergency contact is mandatory for student medical profile.'', 1;

    -- Invariant: Student must belong to specified school
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        LEFT JOIN people.StudentProfile sp ON sp.SchoolId = i.SchoolId AND sp.StudentId = i.StudentId
        WHERE sp.StudentId IS NULL
    )
        THROW 53404, ''Student does not belong to the specified school.'', 1;
END;
';
 EXEC sys.sp_executesql N'
GRANT SELECT, INSERT, UPDATE, DELETE ON health.StudentMedicalProfile TO awn_backend;
GRANT SELECT, INSERT, UPDATE, DELETE ON health.ClinicEncounter TO awn_backend;
';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(34,N''034_clinic_workflows.sql'',0x134c4b470a027cf053740d7eb818e64e7f44d095481ab07cc70f1d75605c36f9,''executed'');';
 -- BEGIN 035_platform_tenancy_workflows.sql
 EXEC sys.sp_executesql N'SET XACT_ABORT ON;
SET NOCOUNT ON;

-- 1. Register Permissions
IF NOT EXISTS (SELECT 1 FROM security.Permission WHERE Code = ''platform.manage'')
    INSERT security.Permission (Code, Description)
    VALUES (''platform.manage'', N''إدارة المنصة والمؤسسات والتراخيص والخطط وإعدادات النظام العامة'');

IF NOT EXISTS (SELECT 1 FROM security.Permission WHERE Code = ''tenancy.read'')
    INSERT security.Permission (Code, Description)
    VALUES (''tenancy.read'', N''استعراض بيانات المؤسسة والمدارس التابعة وحالة التراخيص والخطط'');

IF NOT EXISTS (SELECT 1 FROM security.Permission WHERE Code = ''tenancy.manage'')
    INSERT security.Permission (Code, Description)
    VALUES (''tenancy.manage'', N''إدارة مدارس وفروع المؤسسة وتحديث بياناتها وطلب وتجديد التراخيص'');

-- 2. Map Permissions in security.RolePermission
INSERT security.RolePermission (RoleId, PermissionId)
SELECT r.RoleId, p.PermissionId
FROM security.Role r
CROSS JOIN security.Permission p
WHERE (
    (r.Code = ''platform_owner'' AND p.Code IN (''platform.manage'', ''tenancy.read'', ''tenancy.manage'', ''school.manage'', ''school.read'')) OR
    (r.Code = ''organization_owner'' AND p.Code IN (''tenancy.read'', ''tenancy.manage'', ''school.manage'', ''school.read'')) OR
    (r.Code = ''admin'' AND p.Code IN (''tenancy.read''))
)
AND NOT EXISTS (
    SELECT 1 FROM security.RolePermission rp
    WHERE rp.RoleId = r.RoleId AND rp.PermissionId = p.PermissionId
);
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER TRIGGER core.TR_Organization_Workflow
ON core.Organization
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Invariant: Country code must be 2 uppercase alpha letters
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        WHERE i.CountryCode NOT LIKE ''[A-Z][A-Z]''
    )
        THROW 53500, ''CountryCode must be a 2-letter uppercase ISO code.'', 1;

    -- Invariant: Code must be non-empty and unique
    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE NULLIF(LTRIM(RTRIM(i.Code)), '''') IS NULL
    )
        THROW 53501, ''Organization code is mandatory.'', 1;
END;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER TRIGGER core.TR_School_Workflow
ON core.School
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Invariant: Organization must exist
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        LEFT JOIN core.Organization o ON o.OrganizationId = i.OrganizationId
        WHERE o.OrganizationId IS NULL
    )
        THROW 53502, ''School must belong to a valid organization.'', 1;

    -- Invariant: TimeZoneId is mandatory
    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE NULLIF(LTRIM(RTRIM(i.TimeZoneId)), '''') IS NULL
    )
        THROW 53503, ''TimeZoneId is mandatory for school configuration.'', 1;
END;
';
 EXEC sys.sp_executesql N'
GRANT SELECT, INSERT, UPDATE, DELETE ON core.Organization TO awn_backend;
GRANT SELECT, INSERT, UPDATE, DELETE ON core.School TO awn_backend;
GRANT SELECT, INSERT, UPDATE, DELETE ON core.LicensePlan TO awn_backend;
GRANT SELECT, INSERT, UPDATE, DELETE ON core.OrganizationLicense TO awn_backend;
';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(35,N''035_platform_tenancy_workflows.sql'',0x0eb51f1020309c916f58a0cd24e39f3100d78629e54f85ec046c4fdd98c2f5f6,''executed'');';
 -- BEGIN 036_integrations_delivery_workflows.sql
 EXEC sys.sp_executesql N'SET XACT_ABORT ON;
SET NOCOUNT ON;

-- 1. Register Permissions
IF NOT EXISTS (SELECT 1 FROM security.Permission WHERE Code = ''integrations.read'')
    INSERT security.Permission (Code, Description)
    VALUES (''integrations.read'', N''استعراض سجلات التكامل والتصدير ومزامنة OpenEMIS والمهام الخلفية'');

IF NOT EXISTS (SELECT 1 FROM security.Permission WHERE Code = ''integrations.manage'')
    INSERT security.Permission (Code, Description)
    VALUES (''integrations.manage'', N''إدارة عمليات المزامنة والتصدير والاستيراد والربط مع نظام OpenEMIS والمهام الخلفية'');

IF NOT EXISTS (SELECT 1 FROM security.Permission WHERE Code = ''imports.manage'')
    INSERT security.Permission (Code, Description)
    VALUES (''imports.manage'', N''إدارة ومتابعة حزم استيراد البيانات ومعالجة أخطاء الصفوف'');
ELSE
    UPDATE security.Permission
    SET Description = N''إدارة ومتابعة حزم استيراد البيانات ومعالجة أخطاء الصفوف''
    WHERE Code = ''imports.manage'';

IF NOT EXISTS (SELECT 1 FROM security.Permission WHERE Code = ''notifications.manage'')
    INSERT security.Permission (Code, Description)
    VALUES (''notifications.manage'', N''إدارة وإرسال الإشعارات والتنبيهات المدرسية المباشرة'');

-- 2. Map Permissions in security.RolePermission
INSERT security.RolePermission (RoleId, PermissionId)
SELECT r.RoleId, p.PermissionId
FROM security.Role r
CROSS JOIN security.Permission p
WHERE (
    (r.Code = ''admin'' AND p.Code IN (''integrations.read'', ''integrations.manage'', ''imports.manage'', ''notifications.manage'')) OR
    (r.Code = ''principal'' AND p.Code IN (''integrations.read'', ''integrations.manage'', ''imports.manage'', ''notifications.manage'')) OR
    (r.Code = ''school_admin'' AND p.Code IN (''integrations.read'', ''integrations.manage'', ''imports.manage'', ''notifications.manage'')) OR
    (r.Code = ''platform_owner'' AND p.Code IN (''integrations.read'', ''integrations.manage'', ''imports.manage'', ''notifications.manage''))
)
AND NOT EXISTS (
    SELECT 1 FROM security.RolePermission rp
    WHERE rp.RoleId = r.RoleId AND rp.PermissionId = p.PermissionId
);
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER TRIGGER operations.TR_ExportJob_Workflow
ON operations.ExportJob
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Invariant: EntityType must be non-empty
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        WHERE NULLIF(LTRIM(RTRIM(i.EntityType)), '''') IS NULL
    )
        THROW 53600, ''Export job EntityType is mandatory.'', 1;

    -- Invariant: FormatCode must be non-empty
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        WHERE NULLIF(LTRIM(RTRIM(i.FormatCode)), '''') IS NULL
    )
        THROW 53601, ''Export job FormatCode is mandatory.'', 1;
END;
';
 EXEC sys.sp_executesql N'
CREATE OR ALTER TRIGGER operations.TR_ImportJob_Workflow
ON operations.ImportJob
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Invariant: Total counts integrity
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        WHERE i.ImportedRows + i.RejectedRows > i.TotalRows AND i.TotalRows > 0
    )
        THROW 53602, ''ImportedRows + RejectedRows cannot exceed TotalRows.'', 1;
END;
';
 EXEC sys.sp_executesql N'
GRANT SELECT, INSERT, UPDATE, DELETE ON operations.ExportJob TO awn_backend;
GRANT SELECT, INSERT, UPDATE, DELETE ON operations.ImportJob TO awn_backend;
GRANT SELECT, INSERT, UPDATE, DELETE ON operations.ImportRowError TO awn_backend;
GRANT SELECT, INSERT, UPDATE, DELETE ON learning.Notification TO awn_backend;
';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(36,N''036_integrations_delivery_workflows.sql'',0xca67521b24d9714c67274e4c8ff80bb5d2da1f6d98c95f1a5044cb2ff76d5386,''executed'');';
 -- BEGIN 037_communications_and_platform_permissions.sql
 EXEC sys.sp_executesql N'SET XACT_ABORT ON;
SET NOCOUNT ON;

-- 1. Ensure communication & platform permissions exist
IF NOT EXISTS (SELECT 1 FROM security.Permission WHERE Code = ''communications.read'')
    INSERT security.Permission (Code, Description)
    VALUES (''communications.read'', N''قراءة المحادثات والتعاميم وحجوزات المواعيد والإشعارات'');

IF NOT EXISTS (SELECT 1 FROM security.Permission WHERE Code = ''communications.manage'')
    INSERT security.Permission (Code, Description)
    VALUES (''communications.manage'', N''إدارة التعاميم ونشرها وجدولة المواعيد وإرسال الرسائل'');

IF NOT EXISTS (SELECT 1 FROM security.Permission WHERE Code = ''circulars.read'')
    INSERT security.Permission (Code, Description)
    VALUES (''circulars.read'', N''استعراض التعاميم والإعلانات المدرسية وتأكيد الاطلاع عليها'');

-- 2. Map communication permissions across school roles idempotently
INSERT security.RolePermission (RoleId, PermissionId)
SELECT r.RoleId, p.PermissionId
FROM security.Role r
CROSS JOIN security.Permission p
WHERE (
    (r.Code IN (''admin'', ''principal'', ''school_admin'') AND p.Code IN (''communications.read'', ''communications.manage'', ''circulars.read'')) OR
    (r.Code IN (''supervisor'', ''teacher'', ''parent'', ''student'', ''receptionist'', ''hr_officer'', ''transport_officer'', ''counselor'', ''clinic_staff'', ''finance_officer'', ''registrar'', ''librarian'') AND p.Code IN (''communications.read'', ''circulars.read''))
)
AND NOT EXISTS (
    SELECT 1 FROM security.RolePermission rp
    WHERE rp.RoleId = r.RoleId AND rp.PermissionId = p.PermissionId
);
';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(37,N''037_communications_and_platform_permissions.sql'',0x44e5b7d90c4b6cf1234f5e53017f2723d64ee4010e745d429b7bec20ae661351,''executed'');';
 -- BEGIN 038_import_completion_status.sql
 EXEC sys.sp_executesql N'SET XACT_ABORT ON;
SET NOCOUNT ON;

-- The existing completed_with_errors state contains 21 characters. Keep the
-- established state and all existing records; widen its storage without
-- rewriting any previously recorded migration.
ALTER TABLE operations.ImportJob ALTER COLUMN Status varchar(32) NOT NULL;
';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(38,N''038_import_completion_status.sql'',0x722ebdbe19df17267c028a6b08940cc95ee42c707fae6f6f2d7adecc4bcc5fc3,''executed'');';
 -- BEGIN 039_department_data_permissions.sql
 EXEC sys.sp_executesql N'SET XACT_ABORT ON;
SET NOCOUNT ON;

-- Department ownership approved by the product owner. Read access includes export.
DELETE rp FROM security.RolePermission rp
JOIN security.Role r ON r.RoleId=rp.RoleId
JOIN security.Permission p ON p.PermissionId=rp.PermissionId
WHERE (r.Code=''school_admin'' AND p.Code IN(''integrations.read'',''integrations.manage'',''imports.manage''))
   OR (r.Code=''principal'' AND p.Code IN(''integrations.manage'',''imports.manage''));

INSERT security.RolePermission(RoleId,PermissionId)
SELECT r.RoleId,p.PermissionId FROM security.Role r CROSS JOIN security.Permission p
WHERE ((r.Code IN(''admissions_officer'',''hr_officer'') AND p.Code IN(''integrations.read'',''imports.manage''))
    OR (r.Code=''principal'' AND p.Code IN(''integrations.read'',''profiles.students.read'',''profiles.employees.read'')))
AND NOT EXISTS(SELECT 1 FROM security.RolePermission rp WHERE rp.RoleId=r.RoleId AND rp.PermissionId=p.PermissionId);
';
 EXEC sys.sp_executesql N'INSERT core.SchemaMigration(Version,FileName,FileHash,ApplicationMode) VALUES(39,N''039_department_data_permissions.sql'',0x5e913e1552aeb53e1738735f5f49820b9c46f81a453a9a3163db8e7476fb2a5a,''executed'');';
 IF @@TRANCOUNT<>1 THROW 52570,'Unexpected installation transaction depth.',1;
 COMMIT;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW;
END CATCH;
