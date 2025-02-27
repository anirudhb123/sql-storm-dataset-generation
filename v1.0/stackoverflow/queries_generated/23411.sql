WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY OwnerUserId ORDER BY Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
BadgesSummary AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
CommentsCount AS (
    SELECT 
        PostId, 
        COUNT(*) AS TotalComments
    FROM 
        Comments
    GROUP BY 
        PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY 
        ph.PostId
),
FinalCount AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(bs.GoldBadges, 0) AS GoldBadges,
        COALESCE(bs.SilverBadges, 0) AS SilverBadges,
        COALESCE(bs.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(cc.TotalComments, 0) AS TotalComments,
        COALESCE(cp.LastClosedDate, '1970-01-01'::timestamp) AS LastClosedDate
    FROM 
        Posts p
    LEFT JOIN 
        BadgesSummary bs ON p.OwnerUserId = bs.UserId
    LEFT JOIN 
        CommentsCount cc ON p.Id = cc.PostId
    LEFT JOIN 
        ClosedPosts cp ON p.Id = cp.PostId
)
SELECT 
    f.PostId,
    f.Title,
    f.GoldBadges,
    f.SilverBadges,
    f.BronzeBadges,
    f.TotalComments,
    f.LastClosedDate,
    CASE 
        WHEN f.LastClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open' 
    END AS PostStatus,
    CASE 
        WHEN f.TotalComments > 10 THEN 'High Interaction'
        WHEN f.TotalComments BETWEEN 1 AND 10 THEN 'Moderate Interaction'
        ELSE 'No Interaction' 
    END AS InteractionLevel,
    RANK() OVER (ORDER BY f.GoldBadges DESC, f.SilverBadges DESC, f.BronzeBadges DESC) AS UserBadgeRank
FROM 
    FinalCount f
WHERE 
    f.LastClosedDate IS NULL
    OR f.LastClosedDate > (SELECT MAX(LastClosedDate) FROM ClosedPosts)
ORDER BY 
    f.Score DESC NULLS LAST, 
    f.Title ASC;
