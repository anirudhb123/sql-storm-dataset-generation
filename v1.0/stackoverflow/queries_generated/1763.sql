WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON C.UserId = U.Id
    LEFT JOIN Votes V ON V.UserId = U.Id
    LEFT JOIN Badges B ON B.UserId = U.Id
    GROUP BY U.Id
), 
PostWithDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS Author,
        P.AnswerCount,
        COALESCE(PH.Comment, 'No comment') AS LastEditComment,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY P.CreationDate DESC) AS rn
    FROM 
        Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (4, 5, 6)
)
SELECT 
    U.DisplayName AS UserName,
    U.Upvotes,
    U.Downvotes,
    U.TotalPosts,
    U.TotalComments,
    U.TotalBadges,
    P.Title AS RecentPostTitle,
    P.CreationDate,
    P.ViewCount,
    P.Score,
    P.LastEditComment
FROM 
    UserStats U
LEFT JOIN PostWithDetails P ON U.UserId = P.Author
WHERE 
    U.TotalPosts > 10 AND (U.Upvotes - U.Downvotes) >= 5
    AND P.rn = 1
ORDER BY 
    U.TotalPosts DESC, U.Upvotes DESC
LIMIT 20;
