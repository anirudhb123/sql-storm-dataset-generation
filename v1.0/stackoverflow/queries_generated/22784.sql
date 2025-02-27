WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId, 
        p.OwnerUserId,
        CASE 
            WHEN p.PostTypeId = 1 THEN p.Title
            ELSE NULL
        END AS QuestionTitle,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.ViewCount > 0
),
UserAggregates AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        SUM(p.ViewCount) AS TotalViews,
        CASE 
            WHEN AVG(p.Score) IS NULL THEN 0
            ELSE AVG(p.Score) 
        END AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id AND p.PostTypeId = 1
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id
)
SELECT 
    ua.DisplayName,
    ua.BadgeCount,
    ua.GoldBadges,
    ua.SilverBadges,
    ua.BronzeBadges,
    ua.TotalViews,
    ua.AvgScore,
    rp.PostId,
    rp.QuestionTitle,
    rp.CreationDate,
    rp.Score, 
    rp.ViewCount,
    rp.CommentCount,
    CASE 
        WHEN rp.RecentPostRank = 1 THEN 'Latest Post'
        ELSE 'Older Post'
    END AS PostCategory
FROM 
    UserAggregates ua
LEFT JOIN 
    RecursivePostCTE rp ON ua.UserId = rp.OwnerUserId
WHERE 
    (ua.BadgeCount > 5 OR ua.TotalViews > 1000)
    AND (rp.Score >= (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1))
    OR rp.PostId IS NULL -- Include users with no posts
ORDER BY 
    ua.TotalViews DESC NULLS LAST, 
    ua.AvgScore DESC;

-- Additionally, we can show the closure history from PostHistory
WITH ClosureHistory AS (
    SELECT 
        ph.PostId,
        STRING_AGG(CASE WHEN ph.PostHistoryTypeId IN (10, 11) 
                        THEN CONCAT('Closed on: ', ph.CreationDate::date, ' (Reason: ', COALESCE(cr.Name, 'Unknown'), ')')
                        ELSE NULL END, '; ') AS ClosureDetails
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.*,
    ch.ClosureDetails
FROM 
    RecursivePostCTE rp
LEFT JOIN 
    ClosureHistory ch ON rp.PostId = ch.PostId
WHERE 
    ch.ClosureDetails IS NOT NULL 
    ORDER BY 
    rp.Score DESC;
