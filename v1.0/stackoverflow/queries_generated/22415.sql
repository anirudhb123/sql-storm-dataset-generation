WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS ActivityRank,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '6 months' -- Only consider posts from the last 6 months
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.LastActivityDate, p.OwnerUserId
),

UserWithBadges AS (
    SELECT
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId AND b.Class = 1 -- Gold badges
    GROUP BY 
        u.Id
),

OptimizationTouches AS (
    SELECT 
        pp.PostId,
        pp.Title,
        pp.Score,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        pp.CommentCount,
        pp.TotalBounty,
        CASE 
            WHEN pp.Score > 100 THEN 'High Scorer'
            WHEN pp.Score IS NULL THEN 'No Score'
            ELSE 'Moderate Scorer'
        END AS ScoreCategory,
        CASE 
            WHEN pp.ViewCount = 0 THEN 'No Views'
            WHEN pp.ViewCount < 50 THEN 'Low Views'
            ELSE 'Popular Post'
        END AS ViewCategory
    FROM 
        RankedPosts pp
    LEFT JOIN 
        UserWithBadges ub ON pp.OwnerUserId = ub.UserId
)

SELECT 
    ot.PostId,
    ot.Title,
    ot.Score,
    ot.CommentCount,
    ot.TotalBounty,
    ot.BadgeCount,
    ot.ScoreCategory,
    ot.ViewCategory,
    (SELECT COUNT(*) 
     FROM Votes v1 
     WHERE v1.PostId = ot.PostId 
     AND v1.VoteTypeId = 3) AS DownVotes,
    (SELECT COALESCE(MAX(oh.CreationDate), 'No History') 
     FROM PostHistory oh 
     WHERE oh.PostId = ot.PostId) AS LastEditedDate,
    CASE 
        WHEN ot.ScoreCategory = 'High Scorer' AND ot.ViewCategory = 'Popular Post' 
            THEN 'Outstanding Contribution'
        ELSE 'Needs More Attention'
    END AS PostAssessment
FROM 
    OptimizationTouches ot
WHERE 
    ot.CommentCount > 5
ORDER BY 
    ot.TotalBounty DESC, ot.Score DESC, ot.ViewCount DESC
LIMIT 10;
