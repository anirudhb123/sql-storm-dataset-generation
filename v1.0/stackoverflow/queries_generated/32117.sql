WITH RECURSIVE UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation, 
        0 AS Level
    FROM Users u
    WHERE u.Reputation > 0

    UNION ALL

    SELECT 
        u.Id AS UserId, 
        u.Reputation, 
        ur.Level + 1
    FROM Users u
    INNER JOIN UserReputation ur ON u.Id = ur.UserId 
    WHERE u.Reputation > 0
),

PostDetails AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.AnswerCount, 
        p.CommentCount,
        p.AcceptedAnswerId, 
        u.DisplayName AS OwnerDisplayName,
        PHR.PostHistoryTypeId,
        CASE
            WHEN PHR.PostHistoryTypeId = 10 THEN (SELECT Name FROM CloseReasonTypes WHERE Id = CAST(PHR.Comment AS INT))
            ELSE NULL
        END AS CloseReason
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN PostHistory PHR ON p.Id = PHR.PostId
    WHERE p.CreationDate >= '2023-01-01' -- Filtering posts from this year
),

VoteStatistics AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,  -- Counting UpVotes
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes  -- Counting DownVotes
    FROM Votes
    GROUP BY PostId
),

TagStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT t.TagName) AS TagCount   -- Counting distinct tags for posts
    FROM Posts p
    LEFT JOIN Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY p.Id
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.AnswerCount,
    pd.CommentCount,
    pd.OwnerDisplayName,
    vs.UpVotes,
    vs.DownVotes,
    ts.TagCount,
    pd.CloseReason,
    ur.Reputation AS UserReputation
FROM PostDetails pd
LEFT JOIN VoteStatistics vs ON pd.PostId = vs.PostId
LEFT JOIN TagStatistics ts ON pd.PostId = ts.PostId
LEFT JOIN Users u ON pd.OwnerDisplayName = u.DisplayName
LEFT JOIN UserReputation ur ON u.Id = ur.UserId
WHERE pd.Score > 0  -- Only considering posts with positive score
ORDER BY pd.Score DESC, pd.ViewCount DESC
LIMIT 100;  -- Limiting the result for performance benchmarking
