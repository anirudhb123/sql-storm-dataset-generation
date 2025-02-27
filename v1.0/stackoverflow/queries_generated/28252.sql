WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(v.VoteTypeId = 2) AS UpvotesReceived,
        SUM(v.VoteTypeId = 3) AS DownvotesReceived,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
StringMetrics AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        QuestionsCount,
        AnswersCount,
        UpvotesReceived,
        DownvotesReceived,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        LENGTH(DisplayName) AS DisplayNameLength,
        LENGTH(STRING_AGG(DISTINCT p.Title, ', ')) AS TitleLength,
        LENGTH(STRING_AGG(DISTINCT u.AboutMe, ', ')) AS AboutMeLength
    FROM UserActivity
    LEFT JOIN Posts p ON UserActivity.UserId = p.OwnerUserId
    LEFT JOIN Users u ON UserActivity.UserId = u.Id
    GROUP BY UserId, DisplayName, TotalPosts, QuestionsCount, AnswersCount, UpvotesReceived, DownvotesReceived, GoldBadges, SilverBadges, BronzeBadges
)
SELECT 
    *,
    (CASE 
        WHEN QuestionsCount > 0 THEN CAST(UpvotesReceived AS FLOAT) / QuestionsCount 
        ELSE 0 
    END) AS UpvotePerQuestion,
    (CASE 
        WHEN AnswersCount > 0 THEN CAST(DownvotesReceived AS FLOAT) / AnswersCount 
        ELSE 0 
    END) AS DownvotePerAnswer,
    (GoldBadges + SilverBadges + BronzeBadges) AS TotalBadges
FROM StringMetrics
ORDER BY TotalPosts DESC, UpvotesReceived DESC
LIMIT 10;
