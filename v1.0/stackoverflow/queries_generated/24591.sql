WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(P.AnswerCount), 0) AS TotalAnswers,
        COALESCE(SUM(P.CommentCount), 0) AS TotalComments,
        COUNT(DISTINCT P.Id) FILTER (WHERE P.PostTypeId = 1) AS QuestionCount,
        COUNT(DISTINCT P.Id) FILTER (WHERE P.PostTypeId = 2) AS AnswerCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
RecentActivity AS (
    SELECT 
        UserId,
        MAX(CreationDate) AS LastActiveDate
    FROM Comments
    GROUP BY UserId
),
RankedUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.TotalViews,
        UA.TotalAnswers,
        UA.TotalComments,
        UA.QuestionCount,
        UA.AnswerCount,
        UA.BadgeCount,
        COALESCE(RA.LastActiveDate, '1900-01-01') AS LastActiveDate,
        RANK() OVER (ORDER BY UA.TotalViews DESC, UA.BadgeCount DESC) AS UserRank
    FROM UserActivity UA
    LEFT JOIN RecentActivity RA ON UA.UserId = RA.UserId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalViews,
    U.TotalAnswers,
    U.QuestionCount,
    U.AnswerCount,
    U.BadgeCount,
    U.LastActiveDate,
    CASE 
        WHEN U.BadgeCount > 50 THEN 'Super User'
        WHEN U.BadgeCount BETWEEN 10 AND 50 THEN 'Active User'
        ELSE 'New User'
    END AS UserCategory,
    CASE 
        WHEN DATEDIFF(CURRENT_DATE, U.LastActiveDate) > 365 THEN 'Inactive'
        ELSE 'Active'
    END AS UserStatus
FROM RankedUsers U
WHERE U.UserRank <= 100
ORDER BY U.UserRank, U.TotalViews DESC;

-- Optional additional query for observing NULL logic and operations with string expressions
SELECT 
    U.DisplayName,
    CASE 
        WHEN U.Location IS NULL OR U.Location = '' THEN 'Location Not Specified'
        ELSE U.Location
    END AS UserLocation,
    COALESCE(B.Name, 'No Badge') AS BadgeName,
    LENGTH(COALESCE(B.Comment, '')) AS CommentLength
FROM Users U
LEFT JOIN Badges B ON U.Id = B.UserId
WHERE U.Reputation > 1000
AND (B.Date BETWEEN '2023-01-01' AND CURRENT_DATE OR B.Id IS NULL)
ORDER BY U.DisplayName;
