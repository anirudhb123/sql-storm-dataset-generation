WITH UserBadges AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        BD.Name AS BadgeName, 
        BD.Class,
        BD.Date AS BadgeDate,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY BD.Date DESC) AS BadgeRank
    FROM 
        Users U
    JOIN 
        Badges BD ON U.Id = BD.UserId
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        DENSE_RANK() OVER (ORDER BY SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) DESC) AS UserRanking
    FROM 
        UserBadges
    WHERE 
        BadgeRank = 1
    GROUP BY 
        UserId, DisplayName
),
PostActivity AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(P.Score) AS TotalScore,
        COUNT(C.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.OwnerUserId
),
UserPerformance AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(PA.TotalPosts, 0) AS TotalPosts,
        COALESCE(PA.TotalScore, 0) AS TotalScore,
        COALESCE(PA.CommentCount, 0) AS TotalComments,
        COALESCE(TU.GoldBadges, 0) AS GoldBadges,
        COALESCE(TU.SilverBadges, 0) AS SilverBadges,
        COALESCE(TU.BronzeBadges, 0) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        PostActivity PA ON U.Id = PA.OwnerUserId
    LEFT JOIN 
        TopUsers TU ON U.Id = TU.UserId
)
SELECT 
    UP.UserId,
    UP.DisplayName,
    UP.TotalPosts,
    UP.TotalScore,
    UP.TotalComments,
    UP.GoldBadges,
    UP.SilverBadges,
    UP.BronzeBadges,
    (UP.TotalScore * 1.0 / NULLIF(UP.TotalPosts, 0)) AS AverageScorePerPost
FROM 
    UserPerformance UP
WHERE 
    UP.TotalPosts > 0
ORDER BY 
    UP.TotalScore DESC, 
    UP.TotalPosts DESC
LIMIT 10;

-- Recursive CTE example to find the hierarchy of posts (self-replying threads)
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        Id, 
        ParentId, 
        Title, 
        0 AS Level
    FROM 
        Posts 
    WHERE 
        ParentId IS NULL -- Start with root nodes (questions)
    
    UNION ALL
    
    SELECT 
        P.Id, 
        P.ParentId, 
        P.Title, 
        PH.Level + 1
    FROM 
        Posts P
    INNER JOIN 
        PostHierarchy PH ON P.ParentId = PH.Id
)
SELECT 
    PH.Level,
    PH.Id,
    PH.Title
FROM 
    PostHierarchy PH
ORDER BY 
    PH.Level, 
    PH.Id;

-- Analyzing string expressions and calculating the most common tags used in questions
SELECT 
    TRIM(SPLIT_PART(T.Tags, ',', 1)) AS MostCommonTag,
    COUNT(DISTINCT P.Id) AS PostCount
FROM 
    Posts P
JOIN 
    Tags T ON P.Tags LIKE '%' || T.TagName || '%'
WHERE 
    P.PostTypeId = 1 -- Only questions
GROUP BY 
    TRIM(SPLIT_PART(T.Tags, ',', 1))
ORDER BY 
    PostCount DESC
LIMIT 5;
