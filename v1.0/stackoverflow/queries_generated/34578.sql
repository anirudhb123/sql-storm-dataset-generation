WITH RecursiveTags AS (
    SELECT 
        Id, 
        TagName, 
        Count, 
        ExcerptPostId,
        WikiPostId,
        IsModeratorOnly,
        IsRequired,
        1 AS Level
    FROM Tags
    WHERE IsRequired = 1
    
    UNION ALL
    
    SELECT 
        t.Id, 
        t.TagName, 
        t.Count, 
        t.ExcerptPostId,
        t.WikiPostId,
        t.IsModeratorOnly,
        t.IsRequired,
        rt.Level + 1
    FROM Tags t
    INNER JOIN RecursiveTags rt ON t.Count <= rt.Count AND rt.Level < 3 -- Limit recursion depth to 2
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS RN
    FROM Users u
    WHERE u.Reputation IS NOT NULL
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        MIN(v.CreationDate) AS FirstVoteDate,
        COUNT(DISTINCT pt.UserId) AS TotalVotes,
        MAX(pt.UserId) AS BestVoter
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT PostId, UserId
        FROM Votes
        WHERE VoteTypeId IN (2, 3) -- Upvotes and Downvotes
    ) pt ON pt.PostId = p.Id
    WHERE p.CreationDate >= '2023-01-01'
    GROUP BY p.Id
),
RankedPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.ViewCount,
        ps.CreationDate,
        ps.CommentCount,
        ps.FirstVoteDate,
        ROW_NUMBER() OVER (PARTITION BY ps.Score ORDER BY ps.ViewCount DESC) AS ScoreRank,
        ROW_NUMBER() OVER (ORDER BY ps.ViewCount DESC) AS ViewRank
    FROM PostStats ps
)
SELECT 
    rt.TagName,
    up.DisplayName AS TopUser,
    up.Reputation,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    (SELECT COUNT(*) FROM Votes WHERE PostId = rp.PostId AND VoteTypeId = 2) AS Upvotes,
    (SELECT COUNT(*) FROM Votes WHERE PostId = rp.PostId AND VoteTypeId = 3) AS Downvotes
FROM RankedPosts rp
JOIN RecursiveTags rt ON rp.Title LIKE '%' || rt.TagName || '%'
JOIN UserReputation up ON up.RN = 1 -- Top user by reputation
WHERE rp.ScoreRank = 1 -- Top score posts
    AND rp.ViewRank <= 10 -- Top ten most viewed
ORDER BY rt.TagName, up.Reputation DESC;
