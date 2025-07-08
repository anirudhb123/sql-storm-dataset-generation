
WITH TagData AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        T.TagName,
        T.Count AS TagCount,
        U.Reputation AS UserReputation
    FROM 
        Posts P
    JOIN 
        Tags T ON POSITION(T.TagName IN P.Tags) > 0 
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= DATE_TRUNC('year', CAST('2024-10-01' AS DATE)) 
),

PostStats AS (
    SELECT
        COUNT(DISTINCT PostId) AS TotalPosts,
        AVG(LENGTH(Body)) AS AverageBodyLength,
        AVG(UserReputation) AS AverageUserReputation,
        SUM(TagCount) AS TotalTags
    FROM 
        TagData
)

SELECT
    PS.TotalPosts,
    PS.AverageBodyLength,
    PS.AverageUserReputation,
    PS.TotalTags,
    
    (SELECT COUNT(*) FROM TagData WHERE ARRAY_SIZE(SPLIT(Tags, '>')) > 3) AS PostsWithComplexTags
FROM 
    PostStats PS;
