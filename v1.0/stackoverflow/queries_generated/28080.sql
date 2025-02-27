WITH ProcessedTags AS (
    SELECT 
        p.Id AS PostId,
        LOWER(UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'))) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
), 
TagUsage AS (
    SELECT 
        t.Tag,
        COUNT(pt.PostId) AS PostCount,
        COUNT(DISTINCT p.OwnerUserId) AS UniqueUsers,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgScore
    FROM 
        ProcessedTags t
    JOIN 
        Posts p ON t.PostId = p.Id
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        t.Tag
), 
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        UniqueUsers,
        TotalViews,
        AvgScore,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagUsage
)
SELECT 
    tt.Tag,
    tt.PostCount,
    tt.UniqueUsers,
    tt.TotalViews,
    tt.AvgScore,
    u.DisplayName AS UserWithMostPosts,
    u.Reputation,
    u.Location
FROM 
    TopTags tt
JOIN 
    Posts p ON tt.Tag IN (SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')))
    JOIN Users u ON p.OwnerUserId = u.Id
WHERE 
    tt.TagRank <= 10
ORDER BY 
    tt.PostCount DESC;
