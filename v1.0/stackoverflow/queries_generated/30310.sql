WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
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
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId
),
PostLinksWithScores AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS LinkCount,
        MAX(CASE WHEN pl.LinkTypeId = 3 THEN 1 ELSE 0 END) AS IsDuplicate
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
)
SELECT
    p.Title,
    p.CreationDate,
    up.UserId,
    up.DisplayName,
    ub.BadgeCount,
    ub.BadgeNames,
    p.Score,
    p.ViewCount,
    COALESCE(lp.LinkCount, 0) AS LinkCount,
    MAX(cp.FirstClosedDate) AS FirstClosedDate,
    CASE 
        WHEN lp.IsDuplicate = 1 THEN 'Duplicate'
        ELSE 'Original'
    END AS PostType,
    p.Tags
FROM 
    RankedPosts p
JOIN 
    Users up ON p.OwnerUserId = up.Id
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
LEFT JOIN 
    PostLinksWithScores lp ON p.PostId = lp.PostId
LEFT JOIN 
    ClosedPosts cp ON p.PostId = cp.PostId
WHERE 
    p.PostRank = 1 -- Getting the latest post per user
    AND (p.CreationDate >= NOW() - INTERVAL '30 days') -- Posts created in the last 30 days
GROUP BY 
    p.PostId, up.UserId, ub.BadgeCount, ub.BadgeNames, lp.LinkCount, lp.IsDuplicate
ORDER BY 
    p.Score DESC, p.ViewCount DESC;
