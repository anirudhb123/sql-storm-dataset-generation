WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 3 THEN 1 ELSE 0 END) AS TotalWikis,
        COALESCE(MAX(P.LastActivityDate), '1970-01-01 00:00:00') AS LastActivity
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
TrendingTags AS (
    SELECT 
        T.TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts P
    CROSS JOIN 
        STRING_TO_ARRAY(P.Tags, ',') AS TagName
    JOIN 
        Tags T ON T.TagName = TagName
    WHERE 
        P.CreationDate > CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        T.TagName
    ORDER BY 
        TagCount DESC
    LIMIT 5
),
PostRankings AS (
    SELECT 
        P.Id,
        P.Title,
        P.OwnerUserId,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    WHERE 
        P.CreationDate > CURRENT_DATE - INTERVAL '1 year'
)

SELECT 
    U.Id AS UserId,
    U.DisplayName AS UserName,
    U.Reputation,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    U.TotalWikis,
    U.LastActivity,
    T.TagName AS TrendingTag,
    P.Title AS TopPostTitle,
    P.Score AS PostScore,
    R.Rank
FROM 
    UserStats U
CROSS JOIN 
    TrendingTags T
LEFT JOIN 
    PostRankings P ON U.UserId = P.OwnerUserId
LEFT JOIN 
    (SELECT 
        PostId, COUNT(*) AS CommentCount
     FROM 
        Comments
     GROUP BY 
        PostId) C ON P.Id = C.PostId
WHERE 
    (U.Reputation > 1000 OR U.TotalPosts > 10) 
    AND (P.Rank <= 10 OR P.Rank IS NULL)
ORDER BY 
    U.Reputation DESC, 
    U.LastActivity DESC;
