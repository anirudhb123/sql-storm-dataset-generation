WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS Contributors
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE t.Count > 0
    GROUP BY t.TagName
),
PopularTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        AverageScore,
        Contributors,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS Rank
    FROM TagStats
),
FrequentUsers AS (
    SELECT 
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsContributed,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.ViewCount > 1000 THEN 1 ELSE 0 END) AS HighViewPosts
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.DisplayName
    HAVING COUNT(DISTINCT p.Id) > 5
)
SELECT 
    pt.TagName,
    pt.PostCount,
    pt.TotalViews,
    pt.AverageScore,
    pt.Contributors,
    fu.DisplayName AS TopContributor,
    fu.PostsContributed,
    fu.PositivePosts,
    fu.HighViewPosts
FROM PopularTags pt
JOIN (
    SELECT 
        TagName,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS TagRank
    FROM PopularTags
) tr ON pt.TagName = tr.TagName AND tr.TagRank <= 10
LEFT JOIN FrequentUsers fu ON pt.Contributors LIKE '%' || fu.DisplayName || '%'
ORDER BY pt.TotalViews DESC;
