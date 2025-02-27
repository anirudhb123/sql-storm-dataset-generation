WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        AVG(P.Score) AS AverageScore,
        SUM(P.ViewCount) AS TotalViews,
        STRING_AGG(DISTINCT P.OwnerDisplayName, ', ') AS Authors
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    WHERE 
        P.PostTypeId = 1  -- Only Questions
    GROUP BY 
        T.TagName
), 
TopTags AS (
    SELECT 
        TagName, 
        PostCount,
        AverageScore,
        TotalViews,
        Authors,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStats
) 
SELECT 
    T.TagName,
    T.PostCount,
    T.AverageScore,
    T.TotalViews,
    T.Authors
FROM 
    TopTags T
WHERE 
    T.TagRank <= 10;  -- Top 10 Tags by Post Count

This SQL query computes statistics for the top 10 tags on questions in the Stack Overflow schema, including post counts, average scores, total views, and a list of authors for each tag. The use of CTEs (Common Table Expressions) aids in building an organized query structure and enhances readability.
