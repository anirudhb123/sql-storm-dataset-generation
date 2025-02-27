WITH RECURSIVE PostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL  -- Start from top-level posts (questions)
    
    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.Id  -- Join to find child posts (answers)
),
RecentPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.Score, 
        p.OwnerUserId, 
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'  -- Only consider recent posts
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostVotes AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    ph.Id AS PostId,
    ph.Title,
    ph.Level,
    COALESCE(rb.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(rb.BadgeNames, 'None') AS UserBadgeNames,
    pv.UpVotes,
    pv.DownVotes,
    rp.RecentRank
FROM 
    PostHierarchy ph
LEFT JOIN 
    RecentPosts rp ON ph.Id = rp.Id
LEFT JOIN 
    UserBadges rb ON ph.OwnerUserId = rb.UserId
LEFT JOIN 
    PostVotes pv ON ph.Id = pv.PostId
WHERE 
    ph.Level = 0 OR (ph.Level > 0 AND pv.UpVotes IS NOT NULL)  -- Filter to include specific levels and vote logic
ORDER BY 
    ph.Level, 
    pv.UpVotes DESC NULLS LAST, 
    rp.RecentRank;
This query benchmarks the performance by retrieving a hierarchical structure of posts (questions and answers), along with recent user activity, badge counts, and vote summaries. It incorporates recursive CTEs for hierarchical post retrieval, window functions to rank recent posts by users, and aggregates for user badges. Additionally, it applies a complex filtering logic to ensure specific levels and conditions are included, providing a comprehensive view of the data.
