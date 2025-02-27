WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.ParentId,
        0 AS Level
    FROM Posts P
    WHERE P.PostTypeId = 1 -- Only Questions
    UNION ALL
    SELECT 
        P2.Id,
        P2.Title,
        P2.OwnerUserId,
        P2.ParentId,
        RP.Level + 1
    FROM Posts P2
    INNER JOIN RecursivePostHierarchy RP ON P2.ParentId = RP.PostId
),
UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotesCount,
        SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS NetVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE(UP.QuestionsAsAnswers, 0) AS QuestionsAsAnswers,
        U.UserId,
        U.Reputation,
        U.LastAccessDate,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.CreationDate DESC) AS RN
    FROM Posts P
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(*) AS QuestionsAsAnswers
        FROM Posts
        WHERE PostTypeId = 2 -- Answers
        GROUP BY ParentId
    ) UP ON P.Id = UP.ParentId
    LEFT JOIN UserVoteStats U ON P.OwnerUserId = U.UserId
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.QuestionsAsAnswers,
    U.DisplayName,
    U.Reputation,
    PS.LastAccessDate,
    PH.PostId AS RelatedPostId,
    CASE 
        WHEN PH.Level IS NOT NULL THEN 'Yes'
        ELSE 'No'
    END AS IsParentQuestion
FROM PostStatistics PS
LEFT JOIN RecursivePostHierarchy PH ON PS.PostId = PH.PostId
LEFT JOIN Users U ON PS.UserId = U.Id
WHERE PS.RN = 1 -- Get the latest revision for each Post
  AND (PS.Score > 10 OR PS.ViewCount > 1000) -- Filter for high-scoring or high-view posts
ORDER BY PS.Score DESC, PS.ViewCount DESC
LIMIT 50;
