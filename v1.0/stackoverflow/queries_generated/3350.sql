WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBounties
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id
),
TopTags AS (
    SELECT 
        Tags.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags
    JOIN 
        Posts P ON Tags.Id = P.ExcerptPostId
    GROUP BY 
        Tags.TagName
    HAVING 
        COUNT(P.Id) > 5
),
HighestScoringPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Ranking
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.CommentCount,
    U.TotalBounties,
    TT.TagName,
    HSP.Title AS HighestScoringPostTitle,
    HSP.Score AS HighestScore
FROM 
    UserStats U
LEFT JOIN 
    TopTags TT ON U.PostCount > 10
LEFT JOIN 
    HighestScoringPosts HSP ON HSP.Ranking = 1
ORDER BY 
    U.Reputation DESC,
    U.PostCount DESC
LIMIT 50
OFFSET 0;
