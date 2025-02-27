WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS DownVotes,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
BadgedUsers AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LatestBadgeDate
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
RecentActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.LastAccessDate DESC) AS RecentActivityRank
    FROM 
        Users u
    WHERE 
        u.LastAccessDate > NOW() - INTERVAL '30 days'
)
SELECT 
    ps.Title AS PostTitle,
    ps.CreationDate AS PostCreationDate,
    ps.ViewCount AS PostViewCount,
    ps.UpVotes AS PostUpVotes,
    ps.DownVotes AS PostDownVotes,
    ps.CommentCount AS PostCommentCount,
    bu.BadgeCount AS UserBadgeCount,
    rau.DisplayName AS RecentActiveUserDisplayName,
    CASE 
        WHEN ps.RecentPostRank <= 10 THEN 'Recent Top 10 Questions'
        ELSE 'Older Questions'
    END AS PostCategory,
    COALESCE(ra.RecentActivityRank, 0) AS UserActivityRank
FROM 
    PostStats ps
FULL OUTER JOIN 
    BadgedUsers bu ON ps.PostId = bu.UserId
FULL OUTER JOIN 
    RecentActiveUsers rau ON bu.UserId = rau.Id
WHERE 
    (ps.UpVotes - ps.DownVotes) > 0 -- Only positive scored posts
    AND (bu.BadgeCount > 2 OR rau.Reputation > 100) -- Users with more than 2 badges or high reputation
ORDER BY 
    ps.CreationDate DESC, bu.BadgeCount DESC, rau.Reputation DESC;

-- Note: This query showcases various SQL constructs:
-- 1. CTEs for organizing data
-- 2. Window functions for rankings and counting
-- 3. Outer joins to combine user badge information with post statistics
-- 4. Complex predicates and CASE statements for categorization
-- 5. Aggregation with GROUP BY and use of COALESCE for NULL handling.
