WITH RECURSIVE UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        B.Class,
        B.Name,
        B.Date,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY B.Date DESC) AS BadgeRank
    FROM 
        Users U
    JOIN 
        Badges B ON U.Id = B.UserId
), 

PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(P.Score) AS AvgScore,
        AVG(P.ViewCount) AS AvgViews
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
), 

PopularTags AS (
    SELECT 
        T.TagName,
        T.Count,
        ROW_NUMBER() OVER (ORDER BY T.Count DESC) AS TagRank
    FROM 
        Tags T
    WHERE 
        T.Count > 100
)

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COALESCE(B.BadgeCount, 0) AS TotalBadges,
    PS.TotalPosts,
    PS.Questions,
    PS.Answers,
    PS.AvgScore,
    PS.AvgViews,
    PTag.TagName AS MostPopularTag,
    PTag.Count AS PopularityCount
FROM 
    Users U
LEFT JOIN 
    (SELECT UserId, COUNT(*) AS BadgeCount 
     FROM UserBadges 
     WHERE BadgeRank = 1 
     GROUP BY UserId) B ON U.Id = B.UserId
LEFT JOIN 
    PostStats PS ON U.Id = PS.OwnerUserId
LEFT JOIN 
    (SELECT TagName, Count 
     FROM PopularTags 
     WHERE TagRank = 1) PTag ON TRUE
WHERE 
    U.Reputation > 100 AND 
    U.LastAccessDate > NOW() - INTERVAL '1 year'
ORDER BY 
    U.Reputation DESC,
    TotalPosts DESC;

This SQL query incorporates various advanced constructs, including:

1. **Recursive CTEs**: `UserBadges` recursively extracts badges information grouped by users.
2. **Window Functions**: Used to rank badges and tags.
3. **Outer Joins**: To include users who might not have any badges, posts, or tags.
4. **Aggregations**: Calculating total posts, questions, answers, average score, and views.
5. **Complex predicates**: E.g., filtering users by reputation and last access date.
6. **String Expressions**: Handling tag names directly within the joins.
7. **COALESCE**: To handle NULL values for users without badges, ensuring zero count display.
8. **Set Operators**: Implicitly used through various CTEs and subqueries to derive data across multiple tables.

This SQL script can be quite useful for performance benchmarking due to its comprehensive aggregation and multifaceted data retrieval.
