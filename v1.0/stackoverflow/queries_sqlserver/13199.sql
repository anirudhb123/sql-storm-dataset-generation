
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(ISNULL(V.BountyAmount, 0)) AS TotalBounties,
        SUM(ISNULL(C.Score, 0)) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName
), 
PostEngagement AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        P.CreationDate,
        P.LastActivityDate,
        STRING_AGG(DISTINCT T.TagName, ',') AS Tags
    FROM 
        Posts P
    CROSS APPLY 
        STRING_SPLIT(P.Tags, '<>') AS Tag
    JOIN 
        Tags T ON T.TagName = Tag.value
    WHERE 
        P.CreationDate >= CAST('2024-10-01 12:34:56' AS datetime) - INTERVAL '30 days'
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, P.AnswerCount, P.CommentCount, P.FavoriteCount, P.CreationDate, P.LastActivityDate
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    U.TotalBounties,
    U.TotalComments,
    P.PostId,
    P.Title AS PostTitle,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount,
    P.FavoriteCount,
    P.CreationDate,
    P.LastActivityDate,
    P.Tags
FROM 
    UserStats U
JOIN 
    PostEngagement P ON U.UserId = P.PostId
ORDER BY 
    U.TotalPosts DESC, P.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
