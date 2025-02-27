WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.Views
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (ORDER BY P.Score DESC, P.ViewCount DESC) AS Rank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 month'
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.Views,
    U.UpVoteCount,
    U.DownVoteCount,
    U.PostCount,
    U.CommentCount,
    U.BadgeCount,
    PP.Title AS PopularPostTitle,
    PP.Score AS PopularPostScore,
    PP.ViewCount AS PopularPostViewCount
FROM 
    UserStats U
LEFT JOIN 
    PopularPosts PP ON U.PostCount > 10 AND PP.Rank <= 10
ORDER BY 
    U.Reputation DESC, 
    U.Views DESC NULLS LAST
LIMIT 50;
