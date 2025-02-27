WITH RECURSIVE PostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  -- BountyStart
    WHERE 
        p.PostTypeId = 1  -- Questions only
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
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
RecentPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(v.UserId IS NOT NULL) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  -- UpMod
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'  -- Recent posts
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
PostAggregates AS (
    SELECT 
        cte.PostId,
        cte.Title,
        cte.CreationDate,
        cte.Score,
        cte.ViewCount,
        cte.TotalBounties,
        ub.BadgeCount,
        ub.BadgeNames,
        rp.CommentCount,
        rp.VoteCount
    FROM 
        PostCTE cte
    JOIN 
        UserBadges ub ON cte.OwnerId = ub.UserId
    LEFT JOIN 
        RecentPosts rp ON cte.PostId = rp.PostId
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.Score,
    pa.ViewCount,
    pa.TotalBounties,
    pa.BadgeCount,
    pa.BadgeNames,
    COALESCE(rp.CommentCount, 0) AS CommentCount,
    COALESCE(rp.VoteCount, 0) AS VoteCount
FROM 
    PostAggregates pa
LEFT JOIN 
    PostLinks pl ON pa.PostId = pl.PostId
LEFT JOIN 
    Tags t ON t.ExcerptPostId = pl.RelatedPostId
WHERE 
    pa.TotalBounties > 0 OR pa.VoteCount > 0 OR pa.BadgeCount > 0
ORDER BY 
    pa.Score DESC, pa.CreationDate DESC;
