WITH UserBadgeCounts AS (
    SELECT
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM
        Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostSummary AS (
    SELECT
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AverageViews,
        MAX(p.CreationDate) AS LastPostDate
    FROM
        Posts p
    WHERE
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.OwnerUserId
),
ClosedPostDetails AS (
    SELECT
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.CreationDate END) AS LastClosedDate
    FROM
        PostHistory ph
    GROUP BY
        ph.PostId
),
UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ub.BadgeCount,
        ps.PostCount,
        ps.TotalScore,
        ps.AverageViews,
        COALESCE(cp.LastClosedDate, 'No closures') AS LastClosedDate
    FROM
        Users u
    LEFT JOIN UserBadgeCounts ub ON u.Id = ub.UserId
    LEFT JOIN PostSummary ps ON u.Id = ps.OwnerUserId
    LEFT JOIN ClosedPostDetails cp ON ps.OwnerUserId = cp.PostId
),
FinalResults AS (
    SELECT
        ups.*,
        RANK() OVER (ORDER BY ups.Reputation DESC, ups.TotalScore DESC) AS Rank,
        CASE 
            WHEN ups.Reputation > 10000 THEN 'Elite User'
            WHEN ups.Reputation BETWEEN 5000 AND 10000 THEN 'Experienced User'
            ELSE 'New User'
        END AS UserCategory
    FROM
        UserPostStats ups
)

SELECT 
    UserId,
    DisplayName,
    Reputation,
    BadgeCount,
    PostCount,
    TotalScore,
    AverageViews,
    LastClosedDate,
    Rank,
    UserCategory
FROM 
    FinalResults
WHERE 
    /* Bizarre logic to exclude users with more badges than posts, allowing for NULL checks */
    (BadgeCount IS NULL OR BadgeCount <= PostCount)
ORDER BY 
    Rank, Reputation DESC;
