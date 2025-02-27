
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(COALESCE(p.Score, 0)) AS AvgScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.CommentCount, 0)) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        TotalPosts,
        Questions,
        Answers,
        AvgScore,
        TotalViews,
        TotalComments,
        @PostRank := @PostRank + 1 AS PostRank
    FROM 
        UserPostStats, 
        (SELECT @PostRank := 0) AS r
    ORDER BY 
        TotalPosts DESC
),
PopularTags AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p 
    INNER JOIN 
        (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
        UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1
    WHERE 
        p.Tags IS NOT NULL
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        TagCount,
        @TagRank := @TagRank + 1 AS TagRank
    FROM 
        PopularTags, 
        (SELECT @TagRank := 0) AS r
    ORDER BY 
        TagCount DESC
)
SELECT 
    u.DisplayName,
    u.Reputation,
    tu.PostRank,
    tu.TotalPosts,
    tu.Questions,
    tu.Answers,
    tu.AvgScore,
    tu.TotalViews,
    tu.TotalComments,
    tt.TagName,
    tt.TagCount
FROM 
    Users u
JOIN 
    TopUsers tu ON u.Id = tu.UserId
JOIN 
    TopTags tt ON tu.PostRank = tt.TagRank
WHERE 
    tu.PostRank <= 10 
ORDER BY 
    tu.PostRank, tt.TagCount DESC;
