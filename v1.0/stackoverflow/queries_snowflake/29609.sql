
WITH TagSplit AS (
    SELECT 
        Id AS PostId, 
        TRIM(REGEXP_SUBSTR(Tags, '[^><]+', 1, seq.seq)) AS Tag
    FROM 
        Posts
    JOIN 
        (SELECT ROW_NUMBER() OVER() AS seq FROM TABLE(GENERATOR(ROWCOUNT => 100))) seq
    ON 
        seq.seq <= LENGTH(Tags) - LENGTH(REPLACE(Tags, '><', '')) + 1
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
    (SELECT COUNT(*) FROM Posts P WHERE POSITION(T.Tag IN P.Tags) > 0) AS TotalPosts,
    (SELECT COUNT(*) FROM Comments C WHERE C.PostId IN (SELECT PostId FROM TagSplit WHERE Tag = T.Tag)) AS CommentCount
FROM 
    TopTags T
WHERE 
    T.TagRank <= 10  
ORDER BY 
    T.TagRank;
