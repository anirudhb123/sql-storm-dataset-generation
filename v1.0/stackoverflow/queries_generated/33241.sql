WITH RecursiveUserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        1 AS ActivityLevel
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000

    UNION ALL

    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        ActivityLevel + 1
    FROM 
        Users U
    INNER JOIN 
        Posts P ON U.Id = P.OwnerUserId
    INNER JOIN 
        RecursiveUserActivity R ON P.OwnerUserId = R.UserId
    WHERE 
        R.ActivityLevel < 10
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    COUNT(DISTINCT P.Id) AS TotalPosts,
    COUNT(DISTINCT C.Id) AS TotalComments,
    SUM(COALESCE(V.BountyAmount, 0)) AS TotalBountyAmount,
    MAX(P.CreationDate) AS LastPostDate,
    CASE 
        WHEN MAX(P.Score) IS NULL THEN 0
        ELSE MAX(P.Score)
    END AS MaxScore,
    STRING_AGG(DISTINCT T.TagName, ', ') AS AssociatedTags
FROM 
    RecursiveUserActivity U
LEFT JOIN 
    Posts P ON U.UserId = P.OwnerUserId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId AND V.VoteTypeId = 9  -- Consider only BountyClose type votes
LEFT JOIN 
    LATERAL (SELECT UNNEST(string_to_array(P.Tags, '><'))::varchar[] AS TagName) AS T ON TRUE
WHERE 
    P.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY 
    U.UserId, U.DisplayName, U.Reputation
ORDER BY 
    TotalPosts DESC, MaxScore DESC;

WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        P.Score
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 9
    GROUP BY 
        P.Id, P.Score
),
TopPosts AS (
    SELECT 
        PostId,
        Score,
        CommentCount,
        RANK() OVER (ORDER BY Score DESC, CommentCount DESC) AS Rank
    FROM 
        PostStats
)

SELECT 
    U.DisplayName,
    COUNT(DISTINCT T.PostId) AS PostsRanked,
    AVG(P.Score) AS AveragePostScore
FROM 
    Users U
JOIN 
    Posts P ON U.Id = P.OwnerUserId
JOIN 
    TopPosts T ON P.Id = T.PostId
WHERE 
    T.Rank <= 10
GROUP BY 
    U.DisplayName
ORDER BY 
    AveragePostScore DESC;
