WITH RecursiveCTE AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.AcceptedAnswerId,
        CAST(0 AS INT) AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Only questions
    UNION ALL
    SELECT 
        A.Id,
        A.Title,
        A.CreationDate,
        A.OwnerUserId,
        A.ParentId,
        Level + 1
    FROM 
        Posts A
    INNER JOIN 
        RecursiveCTE Q ON A.ParentId = Q.PostId
    WHERE 
        A.PostTypeId = 2 -- Only answers
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(P.ViewCount) AS TotalViewCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1 -- Join with questions only
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (1, 9) -- Including AcceptedByOriginator and BountyClose
    GROUP BY 
        U.Id, U.DisplayName
),
RecentPostHistory AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.CreationDate,
        PH.Comment,
        PH.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS RN
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) -- Only considering post close and reopen history
        AND PH.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days' -- Last 30 days
)
SELECT 
    RCTE.PostId,
    RCTE.Title,
    RCTE.CreationDate AS QuestionDate,
    U.DisplayName AS Owner,
    U.QuestionCount,
    U.TotalViewCount,
    U.TotalScore,
    U.TotalBounty,
    RP.UserDisplayName AS LastUpdatedBy,
    RP.Comment AS LastActionComment,
    RP.CreationDate AS LastActionDate,
    (SELECT COUNT(*) FROM Comments C WHERE C.PostId = RCTE.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = RCTE.PostId AND V.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = RCTE.PostId AND V.VoteTypeId = 3) AS DownVotes
FROM 
    RecursiveCTE RCTE
JOIN 
    UserStats U ON RCTE.OwnerUserId = U.UserId
LEFT JOIN 
    RecentPostHistory RP ON RCTE.PostId = RP.PostId AND RP.RN = 1 -- Get the latest action on the post
ORDER BY 
    U.TotalScore DESC, RCTE.CreationDate DESC;
