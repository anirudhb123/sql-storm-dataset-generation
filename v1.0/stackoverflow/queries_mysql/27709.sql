
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
        Tags T ON LOCATE(T.TagName, P.Tags) > 0 
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= DATE_FORMAT('2024-10-01', '%Y-01-01') 
),

PostStats AS (
    SELECT
        COUNT(DISTINCT PostId) AS TotalPosts,
        AVG(CHAR_LENGTH(Body)) AS AverageBodyLength,
        AVG(UserReputation) AS AverageUserReputation,
        SUM(TagCount) AS TotalTags
    FROM 
        TagData
    GROUP BY 
        UserReputation
)

SELECT
    PS.TotalPosts,
    PS.AverageBodyLength,
    PS.AverageUserReputation,
    PS.TotalTags,
    
    (SELECT COUNT(*) FROM TagData WHERE LENGTH(SUBSTRING_INDEX(Tags, '>', -1)) > 3) AS PostsWithComplexTags
FROM 
    PostStats PS;
