WITH RecursivePostHierarchy AS (
    -- Get all posts and their parents recursively for answers to questions
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        0 AS Level,
        p.Title,
        p.Score,
        p.AnswerCount,
        p.OwnerUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.ParentId ORDER BY p.CreationDate DESC) AS RowNum
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Starting from questions
    UNION ALL
    SELECT 
        p.Id,
        p.ParentId,
        Level + 1,
        p.Title,
        p.Score,
        p.AnswerCount,
        p.OwnerUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.ParentId ORDER BY p.CreationDate DESC) 
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.PostId
    WHERE p.PostTypeId = 2  -- Answers
),
PostScores AS (
    -- Calculate score metrics including a rank for scores based on their level
    SELECT 
        PostId,
        Level,
        Title,
        Score,
        AnswerCount,
        OwnerUserId,
        CreationDate,
        DENSE_RANK() OVER (ORDER BY SUM(Score) DESC) AS ScoreRank,
        COUNT(CASE WHEN Score > 0 THEN 1 END) OVER (PARTITION BY OwnerUserId) AS PositiveScoreCount
    FROM RecursivePostHierarchy
    GROUP BY PostId, Level, Title, Score, AnswerCount, OwnerUserId, CreationDate
),
LatestVotes AS (
    -- Get the latest votes for the posts and their total votes count
    SELECT 
        v.PostId,
        COUNT(v.Id) AS TotalVotes,
        MAX(v.CreationDate) AS LatestVoteDate
    FROM Votes v
    GROUP BY v.PostId
),
UserReputations AS (
    -- Aggregate user reputation data
    SELECT 
        u.Id AS UserId,
        SUM(u.Reputation) AS TotalReputation,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.AnswerCount,
    ps.OwnerUserId,
    u.TotalReputation,
    u.BadgeCount,
    nv.TotalVotes,
    COALESCE(v.LatestVoteDate, 'No Votes') AS LatestVoteDate,
    CASE 
        WHEN ps.ScoreRank <= 5 THEN 'Top Performance'
        WHEN ps.ScoreRank <= 10 THEN 'Good Performance'
        ELSE 'Needs Improvement'
    END AS PerformanceRank,
    CASE 
        WHEN ps.OwnerUserId IS NULL THEN 'Anonymous'
        ELSE (SELECT DisplayName FROM Users WHERE Id = ps.OwnerUserId)
    END AS OwnerDisplayName
FROM PostScores ps
LEFT JOIN UserReputations u ON ps.OwnerUserId = u.UserId
LEFT JOIN LatestVotes nv ON ps.PostId = nv.PostId
ORDER BY ps.Score DESC, ps.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;  -- Limit to top 50 results

