
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(ISNULL(P.ViewCount, 0)) AS TotalViews,
        SUM(ISNULL(P.Score, 0)) AS TotalScore,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), 
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.LastEditDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        (SELECT COUNT(*) FROM PostHistory PH WHERE PH.PostId = P.Id) AS EditHistoryCount,
        P.OwnerUserId
    FROM 
        Posts P
    WHERE
        P.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.PostCount,
    US.TotalViews,
    US.TotalScore,
    US.CommentCount,
    US.BadgeCount,
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.LastEditDate,
    PS.ViewCount,
    PS.Score,
    PS.AnswerCount,
    PS.CommentCount AS PostCommentCount,
    PS.FavoriteCount,
    PS.EditHistoryCount
FROM 
    UserStats US
JOIN 
    PostStats PS ON US.UserId = PS.OwnerUserId
ORDER BY 
    US.Reputation DESC, PS.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
