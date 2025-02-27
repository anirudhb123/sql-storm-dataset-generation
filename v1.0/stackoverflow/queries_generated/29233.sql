WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(pt.TagName) AS TagCount,
        STRING_AGG(pt.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag ON p.Id = p.Id
    JOIN
        Tags pt ON pt.TagName = tag
    WHERE 
        p.PostTypeId = 1 -- only questions
    GROUP BY 
        p.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Ranking
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000 -- filtering for users with reputation more than 1000
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.UserId,
        ph.Comment,
        ph.Text
    FROM 
        PostHistory ph
    WHERE
        ph.CreationDate >= NOW() - INTERVAL '1 year' -- history from the last year
),
UserPostAnalytics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(p.Score, 0)) AS AverageScore,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS TotalClosedPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        u.Id
),
BenchmarkMetrics AS (
    SELECT 
        u.DisplayName,
        u.TotalPosts,
        u.TotalViews,
        u.AverageScore,
        u.TotalClosedPosts,
        ARRAY_AGG(t.Tags) AS PostTags
    FROM 
        UserPostAnalytics u
    JOIN 
        PostTagCounts t ON u.TotalPosts > 0
    GROUP BY 
        u.DisplayName, u.TotalPosts, u.TotalViews, u.AverageScore, u.TotalClosedPosts
)
SELECT 
    b.DisplayName,
    b.TotalPosts,
    b.TotalViews,
    b.AverageScore,
    b.TotalClosedPosts,
    b.PostTags,
    tu.Ranking
FROM 
    BenchmarkMetrics b
JOIN 
    TopUsers tu ON b.DisplayName = tu.DisplayName
ORDER BY 
    tu.Ranking, b.TotalPosts DESC;
