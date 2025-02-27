
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalBounty,
        @rownum := @rownum + 1 AS UserRank
    FROM 
        UserReputation, (SELECT @rownum := 0) r
    ORDER BY Reputation DESC
),
RecentChanges AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        PH.CreationDate,
        P.Title,
        MAX(PH.CreationDate) AS LastEditDate,
        PH.Comment,
        PH.UserDisplayName,
        PH.PostHistoryTypeId,
        @editRank := IF(@currentPostId = PH.PostId, @editRank + 1, 1) AS EditRank,
        @currentPostId := PH.PostId
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id,
        (SELECT @editRank := 0, @currentPostId := NULL) r
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        PH.UserId, PH.PostId, PH.CreationDate, P.Title, PH.Comment, PH.UserDisplayName, PH.PostHistoryTypeId
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.TotalPosts,
    TU.TotalQuestions,
    TU.TotalAnswers,
    TU.TotalBounty,
    RC.PostId,
    RC.Title,
    RC.LastEditDate,
    RC.Comment,
    RC.UserDisplayName AS Editor,
    RC.PostHistoryTypeId,
    RC.EditRank
FROM 
    TopUsers TU
LEFT JOIN 
    RecentChanges RC ON TU.UserId = RC.UserId
WHERE 
    TU.UserRank <= 10 
    AND (RC.LastEditDate IS NULL OR RC.EditRank = 1)
ORDER BY 
    TU.Reputation DESC, 
    RC.LastEditDate DESC;
