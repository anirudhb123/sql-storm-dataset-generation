
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostAnalytics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.ClosedDate,
        @row_num := IF(@current_user = P.OwnerUserId, @row_num + 1, 1) AS RowNum,
        @current_user := P.OwnerUserId
    FROM 
        Posts P
    CROSS JOIN (SELECT @row_num := 0, @current_user := NULL) AS init
    WHERE 
        P.CreationDate >= NOW() - INTERVAL 6 MONTH
    ORDER BY 
        P.OwnerUserId, P.CreationDate DESC
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.TotalUpVotes,
    U.TotalDownVotes,
    U.TotalPosts,
    U.TotalComments,
    P.Title,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount,
    CASE 
        WHEN P.ClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    UserStatistics U
JOIN 
    PostAnalytics P ON U.UserId = P.OwnerUserId
WHERE 
    U.Reputation > 1000
  AND 
    P.RowNum <= 5
ORDER BY 
    U.Reputation DESC, 
    P.Score DESC;
