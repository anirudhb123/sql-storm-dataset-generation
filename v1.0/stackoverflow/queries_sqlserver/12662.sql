
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
BadgeStats AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    u.UserId,
    u.DisplayName,
    ISNULL(u.PostCount, 0) AS TotalPosts,
    ISNULL(u.QuestionCount, 0) AS TotalQuestions,
    ISNULL(u.AnswerCount, 0) AS TotalAnswers,
    ISNULL(u.UpVotes, 0) AS TotalUpVotes,
    ISNULL(u.DownVotes, 0) AS TotalDownVotes,
    ISNULL(b.BadgeCount, 0) AS TotalBadges,
    ISNULL(b.GoldBadges, 0) AS TotalGoldBadges,
    ISNULL(b.SilverBadges, 0) AS TotalSilverBadges,
    ISNULL(b.BronzeBadges, 0) AS TotalBronzeBadges
FROM UserStats u
FULL OUTER JOIN BadgeStats b ON u.UserId = b.UserId
ORDER BY TotalPosts DESC, TotalUpVotes DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
