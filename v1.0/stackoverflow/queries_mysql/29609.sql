
WITH TagSplit AS (
    SELECT 
        Id AS PostId, 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1  
),
TagSummary AS (
    SELECT 
        Tag,
        COUNT(*) AS PostCount,
        SUM(ViewCount) AS TotalViews,
        AVG(Score) AS AverageScore
    FROM 
        TagSplit
    JOIN 
        Posts ON TagSplit.PostId = Posts.Id
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        TotalViews,
        AverageScore,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagSummary
)
SELECT 
    T.Tag,
    T.PostCount,
    T.TotalViews,
    T.AverageScore,
    (SELECT COUNT(*) FROM Posts P WHERE P.Tags LIKE CONCAT('%%', T.Tag, '%%')) AS TotalPosts,
    (SELECT COUNT(*) FROM Comments C WHERE C.PostId IN (SELECT PostId FROM TagSplit WHERE Tag = T.Tag)) AS CommentCount
FROM 
    TopTags T
WHERE 
    T.TagRank <= 10  
ORDER BY 
    T.TagRank;
