
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        @userRank := @userRank + 1 AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId,
        (SELECT @userRank := 0) AS init
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        @popularityRank := @popularityRank + 1 AS PopularityRank
    FROM 
        Posts P,
        (SELECT @popularityRank := 0) AS init
    WHERE 
        P.CreationDate > (NOW() - INTERVAL 1 YEAR)
    ORDER BY 
        P.Score DESC, P.ViewCount DESC
),
PostWithComments AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(C.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.Title
),
TopPosts AS (
    SELECT 
        PP.PostId,
        PP.Title,
        PP.Score,
        PP.ViewCount,
        PP.AnswerCount,
        PC.CommentCount
    FROM 
        PopularPosts PP
    JOIN 
        PostWithComments PC ON PP.PostId = PC.PostId
    WHERE 
        PP.PopularityRank <= 10
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.TotalBounties,
    U.TotalBadges,
    TP.Title AS TopPostTitle,
    TP.Score AS PostScore,
    TP.ViewCount AS PostViewCount,
    TP.AnswerCount AS PostAnswerCount,
    TP.CommentCount AS PostCommentCount
FROM 
    UserStats U
LEFT JOIN 
    TopPosts TP ON U.UserId = TP.PostId
WHERE 
    U.Reputation > 1000
ORDER BY 
    U.Reputation DESC, 
    TP.Score DESC;
