-- Gulshan Kumar
--UserName: CT_CSI_SQ_5556



CREATE PROCEDURE sp_UpdateSubjectAllotments
AS
BEGIN
    SET NOCOUNT ON;

    -- Iterate over each record in SubjectRequest
    DECLARE @StudentId VARCHAR(50);
    DECLARE @RequestedSubjectId VARCHAR(50);
    DECLARE subject_cursor CURSOR FOR
        SELECT StudentId, SubjectId FROM SubjectRequest;

    OPEN subject_cursor;
    FETCH NEXT FROM subject_cursor INTO @StudentId, @RequestedSubjectId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Check if the student exists in SubjectAllotments
        IF EXISTS (SELECT 1 FROM SubjectAllotments WHERE StudentId = @StudentId)
        BEGIN
            -- Get current active subject (Is_valid = 1)
            DECLARE @CurrentSubjectId VARCHAR(50);
            SELECT @CurrentSubjectId = SubjectId 
            FROM SubjectAllotments 
            WHERE StudentId = @StudentId AND Is_valid = 1;

            -- If current subject is different from requested one
            IF @CurrentSubjectId IS NULL OR @CurrentSubjectId <> @RequestedSubjectId
            BEGIN
                -- Invalidate current subject (set Is_valid = 0)
                UPDATE SubjectAllotments
                SET Is_valid = 0
                WHERE StudentId = @StudentId AND Is_valid = 1;

                -- Insert new subject as active (Is_valid = 1)
                INSERT INTO SubjectAllotments (StudentId, SubjectId, Is_valid)
                VALUES (@StudentId, @RequestedSubjectId, 1);
            END
            -- ELSE: Do nothing if already same subject
        END
        ELSE
        BEGIN
            -- Student does not exist in SubjectAllotments, insert new record as valid
            INSERT INTO SubjectAllotments (StudentId, SubjectId, Is_valid)
            VALUES (@StudentId, @RequestedSubjectId, 1);
        END

        -- Move to next student request
        FETCH NEXT FROM subject_cursor INTO @StudentId, @RequestedSubjectId;
    END

    CLOSE subject_cursor;
    DEALLOCATE subject_cursor;

    -- Optionally, clear SubjectRequest table after processing
    -- DELETE FROM SubjectRequest;
END;
