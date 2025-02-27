WITH UserReputation AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
RecentPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
AcceptedAnswers AS (
    SELECT 
        Q.Id AS QuestionId,
        A.Id AS AnswerId,
        A.OwnerUserId AS AnswererId
    FROM 
        Posts Q
    JOIN 
        Posts A ON Q.AcceptedAnswerId = A.Id
    WHERE 
        Q.PostTypeId = 1 -- Questions
),
VoteCounts AS (
    SELECT 
        P.Id AS PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),
PostHistoryUpdates AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        PH.Comment,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS UpdateRank
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11, 12, 13) -- Closed, Reopened, Deleted, Undeleted
)
SELECT 
    U.DisplayName AS UserName,
    U.Reputation AS UserReputation,
    U.CreationDate AS UserCreationDate,
    COUNT(DISTINCT R.PostId) FILTER (WHERE R.RecentPostRank = 1) AS RecentPostCount,
    COALESCE(PH.UpdateRank, 0) AS PostUpdateRank,
    V.UpVoteCount,
    V.DownVoteCount,
    PA.QuestionId,
    PA.AnswerId
FROM 
    UserReputation U
LEFT JOIN 
    RecentPosts R ON U.Id = R.OwnerUserId
LEFT JOIN 
    VoteCounts V ON R.PostId = V.PostId
LEFT JOIN 
    AcceptedAnswers PA ON U.Id = PA.AnswererId
LEFT JOIN 
    PostHistoryUpdates PH ON R.PostId = PH.PostId 
WHERE 
    U.Reputation > 1000 -- Only users with reasonable reputation
    AND (R.RecentPostCount > 0 OR PA.QuestionId IS NOT NULL)
GROUP BY 
    U.Id, U.DisplayName, U.Reputation, U.CreationDate, PH.UpdateRank, V.UpVoteCount, V.DownVoteCount, PA.QuestionId, PA.AnswerId
ORDER BY 
    U.Reputation DESC, RecentPostCount DESC, UpVoteCount DESC;
