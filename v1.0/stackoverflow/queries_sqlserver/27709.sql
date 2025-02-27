
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
        Tags T ON CHARINDEX(T.TagName, P.Tags) > 0 
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= DATEADD(year, DATEDIFF(year, 0, '2024-10-01'), 0)
),

PostStats AS (
    SELECT
        COUNT(DISTINCT PostId) AS TotalPosts,
        AVG(DATALENGTH(Body)) AS AverageBodyLength,
        AVG(UserReputation) AS AverageUserReputation,
        SUM(TagCount) AS TotalTags
    FROM 
        TagData
    GROUP BY 
        PostId, Body, Tags, UserReputation
)

SELECT
    PS.TotalPosts,
    PS.AverageBodyLength,
    PS.AverageUserReputation,
    PS.TotalTags,
    
    (SELECT COUNT(*) FROM TagData WHERE LEN(Tags) - LEN(REPLACE(Tags, '>', '')) > 3) AS PostsWithComplexTags
FROM 
    PostStats PS;
