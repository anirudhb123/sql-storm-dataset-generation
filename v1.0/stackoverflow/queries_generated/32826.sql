WITH RecursiveCTE AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.Score,
        P.CreationDate,
        P.ParentId,
        0 AS Depth
    FROM Posts P
    WHERE P.PostTypeId = 1  -- Start with questions
    UNION ALL
    SELECT 
        P2.Id,
        P2.Title,
        P2.OwnerUserId,
        P2.Score,
        P2.CreationDate,
        P2.ParentId,
        Depth + 1
    FROM Posts P2
    INNER JOIN RecursiveCTE R ON P2.ParentId = R.PostId
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        COALESCE(SUM(P.Score), 0) AS TotalScore,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalAnswers,
        COALESCE(MAX(B.Date), 'No badges') AS LastBadgeDate
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostCommentStats AS (
    SELECT 
        P.Id AS PostId,
        COUNT(C.Id) AS CommentCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.Id
)

SELECT 
    U.DisplayName,
    U.TotalPosts,
    U.TotalScore,
    U.TotalAnswers,
    PC.CommentCount,
    R.Depth AS AnswerDepth,
    R.Title AS QuestionTitle,
    R.CreationDate AS QuestionDate,
    CASE 
        WHEN MAX(B.Class) = 1 THEN 'Gold'
        WHEN MAX(B.Class) = 2 THEN 'Silver'
        WHEN MAX(B.Class) = 3 THEN 'Bronze'
        ELSE 'No badges'
    END AS HighestBadge
FROM UserPostStats U
LEFT JOIN PostCommentStats PC ON PC.PostId = U.UserId
LEFT JOIN RecursiveCTE R ON R.OwnerUserId = U.UserId
LEFT JOIN Badges B ON U.UserId = B.UserId
WHERE U.TotalPosts > 0
GROUP BY U.UserId, U.DisplayName, U.TotalPosts, U.TotalScore, U.TotalAnswers, PC.CommentCount, R.Depth, R.Title, R.CreationDate
ORDER BY U.TotalScore DESC, U.TotalPosts DESC, R.Depth ASC
LIMIT 100;
