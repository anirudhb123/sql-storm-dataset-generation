WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    WHERE 
        U.Reputation IS NOT NULL
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.ParentId IS NULL THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN P.ParentId IS NOT NULL THEN 1 END) AS TotalAnswers
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
)
SELECT 
    RU.DisplayName,
    RU.Reputation,
    UPS.TotalPosts,
    UPS.TotalQuestions,
    UPS.TotalAnswers,
    COALESCE(PHT.PostHistoryCount, 0) AS PostHistoryCount,
    COALESCE(PVC.ViewCount, 0) AS MostViewedPost,
    P.Title AS MostViewedPostTitle
FROM 
    RankedUsers RU
JOIN 
    UserPostStats UPS ON RU.UserId = UPS.UserId
LEFT JOIN (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS PostHistoryCount
    FROM 
        PostHistory PH
    WHERE 
        PH.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        PH.UserId
) PHT ON RU.UserId = PHT.UserId
LEFT JOIN (
    SELECT 
        P.OwnerUserId,
        MAX(P.ViewCount) AS ViewCount
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
) PVC ON RU.UserId = PVC.OwnerUserId
LEFT JOIN 
    Posts P ON P.OwnerUserId = RU.UserId AND P.ViewCount = PVC.ViewCount
WHERE 
    RU.ReputationRank <= 10
ORDER BY 
    RU.Reputation DESC
LIMIT 10;

-- Now include duplicate checking with strings and NULL logic
WITH DuplicateTags AS (
    SELECT 
        T.TagName,
        COUNT(*) AS TagCount
    FROM 
        Tags T
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(*) > 1
),
PostTagStats AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostsWithTagCount
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON POSITION(T.TagName IN P.Tags) > 0 -- Use string matching
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(P.Id) > 0
)
SELECT 
    DT.TagName,
    DT.TagCount,
    COALESCE(PTS.PostsWithTagCount, 0) AS PostsWithTagCount
FROM 
    DuplicateTags DT
LEFT JOIN 
    PostTagStats PTS ON DT.TagName = PTS.TagName
ORDER BY 
    DT.TagCount DESC;

-- Check for conditions where count of posts is null
SELECT 
    U.DisplayName,
    COUNT(P.Id) AS TotalPosts
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
GROUP BY 
    U.DisplayName
HAVING 
    COUNT(P.Id) IS NULL 
    OR COUNT(P.Id) = 0;
