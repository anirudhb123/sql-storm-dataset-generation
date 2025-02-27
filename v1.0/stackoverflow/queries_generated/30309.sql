WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.PostTypeId, 
        p.ParentId,
        0 AS Level
    FROM Posts p
    WHERE p.ParentId IS NULL  -- Starting point: root posts (Questions)
    
    UNION ALL
    
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.PostTypeId, 
        p.ParentId,
        r.Level + 1 AS Level
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.PostId  -- Join to get child posts
),
AggregateVotes AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVoteCount,  -- Counting Upvotes
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVoteCount -- Counting Downvotes
    FROM Votes
    GROUP BY PostId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN ph.Comment IS NOT NULL THEN 1 ELSE 0 END) AS PostHistoryCount -- Counting post history entries
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id
)
SELECT 
    p.Title,
    p.ViewCount,
    ph.Level,
    av.UpVoteCount,
    av.DownVoteCount,
    ua.UserId,
    ub.BadgeCount,
    ub.HighestBadgeClass,
    pa.CommentCount,
    pa.PostHistoryCount
FROM RecursivePostHierarchy ph
JOIN Posts p ON p.Id = ph.PostId
LEFT JOIN AggregateVotes av ON av.PostId = p.Id
LEFT JOIN UserBadges ub ON ub.UserId = p.OwnerUserId
LEFT JOIN PostActivity pa ON pa.PostId = p.Id
WHERE 
    p.CreationDate >= DATEADD(year, -1, GETDATE()) -- Posts created in the last year
    AND p.ViewCount > 100  -- Filter for popular posts
ORDER BY 
    ph.Level DESC, 
    av.UpVoteCount DESC, 
    pa.CommentCount DESC;
