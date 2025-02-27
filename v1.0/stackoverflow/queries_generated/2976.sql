WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END), 0) AS TotalViews,
        COALESCE(SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END), 0) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(t.TagName, ',')) AS TagName,
        COUNT(pt.PostId) AS TagCount
    FROM 
        Tags t
    JOIN 
        Posts pt ON t.ExcerptPostId = pt.Id
    GROUP BY 
        TagName
),
RecentPostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
)
SELECT 
    ua.DisplayName,
    ua.Reputation,
    ua.TotalViews,
    ua.TotalScore,
    ua.PostCount,
    pt.TagName,
    pt.TagCount,
    rpa.RecentPostId,
    rpa.Title AS RecentPostTitle,
    rpa.CreationDate AS RecentPostDate
FROM 
    UserActivity ua
LEFT JOIN 
    PopularTags pt ON ua.PostCount > 0
LEFT JOIN 
    RecentPostAnalytics rpa ON ua.UserId = rpa.PostId
WHERE 
    ua.Reputation > (SELECT AVG(Reputation) FROM Users)
    AND pt.TagCount >= 5
ORDER BY 
    ua.TotalScore DESC, 
    ua.TotalViews DESC
LIMIT 10;
