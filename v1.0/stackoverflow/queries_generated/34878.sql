WITH RecursivePostHierarchy AS (
    -- This CTE retrieves all posts along with their hierarchy for answering
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ParentId,
        1 AS HierarchyLevel
    FROM Posts P
    WHERE P.PostTypeId = 1  -- Only questions
    UNION ALL
    SELECT 
        P.Id,
        P.Title,
        P.ParentId,
        R.HierarchyLevel + 1
    FROM Posts P
    JOIN RecursivePostHierarchy R ON P.ParentId = R.PostId
),
UserStats AS (
    -- This CTE computes total votes and scores for users with a cutoff for reputation
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.Reputation
),
ClosedPosts AS (
    -- This CTE retrieves details about closed posts and their close reasons
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.Comment AS CloseReason,
        COUNT(PH.UserId) AS CloseVotes
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId = 10  -- Closed posts
    GROUP BY PH.PostId, PH.CreationDate, PH.Comment
),
RankedPosts AS (
    -- This CTE ranks posts based on their score and activity
    SELECT 
        P.Id,
        P.Title,
        P.Score,
        RANK() OVER (ORDER BY P.Score DESC, P.CreationDate DESC) AS PostRank
    FROM Posts P
    WHERE P.PostTypeId = 1 -- Only questions
)
SELECT 
    R.Title AS QuestionTitle,
    R.Score AS QuestionScore,
    RP.PostRank,
    U.DisplayName AS TopVoter,
    US.TotalVotes,
    US.UpVotes,
    US.DownVotes,
    COALESCE(CP.CloseReason, 'Not Closed') AS CloseReason,
    COALESCE(CP.CloseVotes, 0) AS CloseVoteCount,
    (SELECT COUNT(C.Id) 
     FROM Comments C 
     WHERE C.PostId = R.Id) AS CommentCount,
    PH.HierarchyLevel
FROM RankedPosts R
LEFT JOIN UserStats US ON R.Score = US.UpVotes
LEFT JOIN ClosedPosts CP ON R.Id = CP.PostId
LEFT JOIN RecursivePostHierarchy PH ON R.Id = PH.PostId
WHERE US.Reputation < 5000 -- Filter users by reputation
AND (US.UpVotes IS NOT NULL OR US.DownVotes IS NOT NULL)
ORDER BY QuestionScore DESC, CloseVoteCount DESC, PostRank ASC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
