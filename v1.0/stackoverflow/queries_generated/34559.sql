WITH RecursivePosts AS (
    SELECT 
        Id,
        Title,
        CreationDate,
        ViewCount,
        OwnerUserId,
        ParentId,
        PostTypeId,
        Score,
        1 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        p.ParentId,
        p.PostTypeId,
        p.Score,
        rp.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePosts rp ON p.ParentId = rp.Id
),

PostVoteStats AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM 
        Votes
    GROUP BY 
        PostId
),

UserBadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS TotalBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),

PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN ph.CreationDate END) AS LastTitleEdit,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.CreationDate END) AS LastCloseReopenDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.Id AS PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    ps.Upvotes,
    ps.Downvotes,
    ub.TotalBadges AS UserTotalBadges,
    pld.LastEditDate,
    pld.LastTitleEdit,
    pld.LastCloseReopenDate,
    CASE 
        WHEN pld.LastCloseReopenDate IS NOT NULL THEN 'Closed/Reopened'
        ELSE 'Active'
    END AS PostStatus,
    CASE 
        WHEN rp.ViewCount > 1000 THEN 'High View Count'
        WHEN rp.ViewCount BETWEEN 500 AND 1000 THEN 'Moderate View Count'
        ELSE 'Low View Count'
    END AS ViewCountCategory,
    ROW_NUMBER() OVER (PARTITION BY rp.Level ORDER BY rp.Score DESC) AS RankWithinLevel
FROM 
    RecursivePosts rp
LEFT JOIN 
    PostVoteStats ps ON rp.Id = ps.PostId
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserBadgeCounts ub ON u.Id = ub.UserId
LEFT JOIN 
    PostHistoryDetails pld ON rp.Id = pld.PostId
WHERE 
    rp.PostTypeId = 1  -- Refining to questions only
ORDER BY 
    rp.Level, rp.Score DESC
OPTION (MAXRECURSION 100);  -- Limit recursion depth if necessary
