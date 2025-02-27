WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
    WHERE 
        u.Reputation > 0
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
RecentPostActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Posts p
    WHERE 
        p.CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY 
        p.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS ClosedCount
    FROM 
        Posts p
    WHERE 
        p.ClosedDate IS NOT NULL
    GROUP BY 
        p.OwnerUserId
),
UserSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(rb.BadgeCount, 0) AS BadgeCount,
        COALESCE(rp.PostCount, 0) AS RecentPostCount,
        COALESCE(cu.ClosedCount, 0) AS ClosedPostCount,
        COALESCE(pu.TotalViews, 0) AS TotalPostViews
    FROM 
        Users u
    LEFT JOIN UserBadges rb ON u.Id = rb.UserId
    LEFT JOIN RecentPostActivity rp ON u.Id = rp.OwnerUserId
    LEFT JOIN ClosedPosts cu ON u.Id = cu.OwnerUserId
    LEFT JOIN RecentPostActivity pu ON u.Id = pu.OwnerUserId
),
FinalSummary AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.BadgeCount,
        us.RecentPostCount,
        us.ClosedPostCount,
        us.TotalPostViews,
        CASE 
            WHEN us.RecentPostCount > 10 THEN 'High Activity'
            WHEN us.RecentPostCount BETWEEN 5 AND 10 THEN 'Moderate Activity'
            ELSE 'Low Activity'
        END AS ActivityLevel,
        RANK() OVER (ORDER BY us.BadgeCount DESC) AS BadgeRank
    FROM 
        UserSummary us
)
SELECT 
    fs.UserId,
    fs.DisplayName,
    fs.BadgeCount,
    fs.RecentPostCount,
    fs.ClosedPostCount,
    fs.TotalPostViews,
    fs.ActivityLevel,
    fs.BadgeRank
FROM 
    FinalSummary fs
WHERE 
    fs.ClosedPostCount = (
        SELECT MAX(ClosedPostCount) 
        FROM FinalSummary
    )
ORDER BY 
    fs.Reputation DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;

-- Additional insights with respect to Posts and Comments
SELECT 
    p.OwnerDisplayName,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(CASE WHEN c.Score < 0 THEN 1 ELSE 0 END) AS NegativeComments,
    COUNT(DISTINCT pp.Id) AS RelatedPosts
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    PostLinks pp ON p.Id = pp.PostId
WHERE 
    p.CreationDate > NOW() - INTERVAL '1 year'
GROUP BY 
    p.OwnerDisplayName
HAVING 
    SUM(CASE WHEN c.Score < 0 THEN 1 ELSE 0 END) > 2
ORDER BY 
    p.OwnerDisplayName;
