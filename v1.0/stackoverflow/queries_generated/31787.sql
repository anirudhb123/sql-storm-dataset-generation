WITH RecursivePostChain AS (
    -- Start from posts that are top-level questions (PostTypeId=1) and find their answers recursively
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.AcceptedAnswerId,
        P.AnswerCount,
        P.Score,
        1 AS Depth
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1

    UNION ALL

    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.AcceptedAnswerId,
        P.AnswerCount,
        P.Score,
        RPC.Depth + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostChain RPC ON P.ParentId = RPC.PostId
),

PostMetrics AS (
    -- Collect metrics for each post including user reputation
    SELECT 
        RPC.PostId,
        RPC.Title,
        RPC.CreationDate,
        U.Reputation,
        U.DisplayName,
        RPC.Depth,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS DownVotes,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT H.Id) AS HistoryCount
    FROM 
        RecursivePostChain RPC
    LEFT JOIN 
        Users U ON RPC.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON RPC.PostId = V.PostId
    LEFT JOIN 
        Comments C ON RPC.PostId = C.PostId
    LEFT JOIN 
        PostHistory H ON RPC.PostId = H.PostId
    GROUP BY 
        RPC.PostId, RPC.Title, RPC.CreationDate, U.Reputation, U.DisplayName, RPC.Depth
),

FilteredPosts AS (
    SELECT * 
    FROM PostMetrics 
    WHERE Depth = 1 AND Reputation >= 100 -- Focus only on top-level questions by users with enough reputation
),

RankedPosts AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY Depth ORDER BY UpVotes DESC, DownVotes ASC) AS RN,
           AVG(Reputation) OVER() AS AvgReputation
    FROM FilteredPosts
)

SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.DisplayName,
    RP.Reputation,
    RP.UpVotes,
    RP.DownVotes,
    RP.CommentCount,
    RP.HistoryCount,
    CASE 
        WHEN RP.Reputation > RP.AvgReputation THEN 'Above Average Reputation'
        ELSE 'Below Average Reputation'
    END AS ReputationStatus
FROM 
    RankedPosts RP
WHERE 
    RP.RN <= 10 -- Get top 10 ranked posts
ORDER BY 
    RP.UpVotes DESC, RP.CreationDate DESC;

-- The above query benchmarks post performance based on votes, reputation, comments, and history 
-- while utilizing CTEs, joins, window functions, and grouping for aggregation. 
