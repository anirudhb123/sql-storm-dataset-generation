
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounties,
        SUM(COALESCE(C.Score, 0)) AS TotalComments
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
        GROUP_CONCAT(DISTINCT T.TagName) AS Tags
    FROM 
        Posts P
    LEFT JOIN 
        (SELECT 
            P.Id, 
            SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '<>', numbers.n), '<>', -1) TagName
        FROM  
            (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
             UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) 
        numbers INNER JOIN Posts P ON CHAR_LENGTH(P.Tags) 
            -CHAR_LENGTH(REPLACE(P.Tags, '<>', ''))>=numbers.n-1) AS Tag
    JOIN 
        Tags T ON T.TagName = Tag.TagName
    WHERE 
        P.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 30 DAY
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
LIMIT 100;
