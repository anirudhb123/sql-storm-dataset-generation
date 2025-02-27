WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(P.Score) AS AverageScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        AverageScore,
        LastPostDate,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserPostStats
    WHERE 
        TotalPosts > 0
),
ActiveUserTags AS (
    SELECT 
        U.Id AS UserId,
        T.TagName,
        COUNT(P.Id) AS PostsWithTag
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    JOIN 
        STRING_TO_ARRAY(P.Tags, ',') AS TagList ON true
    JOIN 
        Tags T ON T.TagName = TagList
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        U.Id, T.TagName
)
SELECT 
    TU.UserId,
    TU.Reputation,
    TU.TotalPosts,
    TU.TotalQuestions,
    TU.TotalAnswers,
    TU.AverageScore,
    TU.LastPostDate,
    STRING_AGG(DISTINCT A.TagName ORDER BY A.PostsWithTag DESC) AS ActiveTags,
    COALESCE(NULLIF(CAST(NULLIF(AVG(V.BountyAmount), 0) AS INT), 0), 0), 0) AS AverageBounty 
FROM 
    TopUsers TU
LEFT JOIN 
    ActiveUserTags A ON TU.UserId = A.UserId
LEFT JOIN 
    Votes V ON TU.UserId = V.UserId AND V.CreationDate >= NOW() - INTERVAL '1 month'
WHERE 
    TU.Rank <= 10
GROUP BY 
    TU.UserId, TU.Reputation, TU.TotalPosts, TU.TotalQuestions, TU.TotalAnswers, TU.AverageScore, TU.LastPostDate
ORDER BY 
    TU.Reputation DESC;
