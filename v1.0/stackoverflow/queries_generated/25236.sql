WITH TagStatistics AS (
    SELECT 
        T.TagName,
        P.Title AS PostTitle,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(P.Score) AS AverageScore,
        MIN(P.CreationDate) AS FirstPostDate,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%')
    GROUP BY 
        T.TagName, P.Title
), 
UserActivity AS (
    SELECT 
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        MAX(U.Reputation) AS MaxReputation
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON C.UserId = U.Id
    LEFT JOIN 
        Badges B ON B.UserId = U.Id
    GROUP BY 
        U.DisplayName
),
CloseReasonCount AS (
    SELECT 
        P.Title,
        COUNT(PH.Id) AS CloseAttempts,
        STRING_AGG(DISTINCT CRT.Name, ', ') AS CloseReasons
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON PH.PostId = P.Id AND PH.PostHistoryTypeId = 10
    JOIN 
        CloseReasonTypes CRT ON PH.Comment::int = CRT.Id
    GROUP BY 
        P.Title
)

SELECT 
    T.TagName,
    T.TotalPosts,
    T.QuestionCount,
    T.AnswerCount,
    T.AverageScore,
    T.FirstPostDate,
    T.LastPostDate,
    UA.DisplayName AS ActiveUser,
    UA.PostCount AS UserPostCount,
    UA.CommentCount AS UserCommentCount,
    UA.BadgeCount AS UserBadgeCount,
    UA.MaxReputation AS UserMaxReputation,
    CRC.CloseAttempts,
    CRC.CloseReasons
FROM 
    TagStatistics T
JOIN 
    UserActivity UA ON UA.PostCount > 0
LEFT JOIN 
    CloseReasonCount CRC ON CRC.Title = T.PostTitle
WHERE 
    T.TotalPosts > 5
ORDER BY 
    T.AverageScore DESC, UA.MaxReputation DESC
LIMIT 10;
