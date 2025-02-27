WITH RecursiveTopAnswerers AS (
    -- CTE to find the top answerers who have provided answers to questions with a high score
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(A.Id) AS AnswerCount,
        SUM(A.Score) AS TotalScore
    FROM Users U
    JOIN Posts Q ON U.Id = Q.OwnerUserId
    JOIN Posts A ON Q.Id = A.ParentId AND A.PostTypeId = 2
    WHERE Q.PostTypeId = 1 AND A.Score > 10
    GROUP BY U.Id, U.DisplayName
), 
RankedAnswers AS (
    -- CTE to rank users based on the number of answers and total score
    SELECT 
        UserId,
        DisplayName,
        AnswerCount,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC, AnswerCount DESC) AS AnswerRank
    FROM RecursiveTopAnswerers
),
UserBadges AS (
    -- CTE to gather badges earned by top answerers
    SELECT 
        U.Id AS UserId,
        B.Name AS BadgeName,
        B.Class AS BadgeClass
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
),
FilteredBadges AS (
    -- Filter for only Gold and Silver badges
    SELECT *
    FROM UserBadges
    WHERE BadgeClass IN (1, 2)
),
UserStats AS (
    -- Combine ranked answers with badge information for top 5 answerers
    SELECT 
        R.DisplayName,
        R.AnswerCount,
        R.TotalScore,
        STRING_AGG(DISTINCT FB.BadgeName, ', ') AS Badges
    FROM RankedAnswers R
    LEFT JOIN FilteredBadges FB ON R.UserId = FB.UserId
    WHERE R.AnswerRank <= 5
    GROUP BY R.DisplayName, R.AnswerCount, R.TotalScore
)
-- Final results with performance metrics
SELECT 
    US.DisplayName,
    US.AnswerCount,
    US.TotalScore,
    COALESCE(US.Badges, 'No Badges') AS Badges,
    (SELECT COUNT(*) FROM Posts P WHERE P.OwnerUserId = US.DisplayNameId) AS TotalPosts,
    (SELECT AVG(ViewCount) FROM Posts P WHERE P.OwnerUserId = US.DisplayNameId) AS AvgViewCount
FROM UserStats US
ORDER BY US.TotalScore DESC;

