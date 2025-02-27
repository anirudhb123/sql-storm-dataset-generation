WITH UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(v.VoteCount) AS AvgVotes,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
        FROM Votes 
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation > 100
    GROUP BY u.Id, u.DisplayName
),
TopPerformers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY TotalPosts DESC, AvgVotes DESC) AS Rank
    FROM UserPerformance
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    AvgVotes,
    GoldBadges,
    SilverBadges,
    BronzeBadges
FROM TopPerformers
WHERE Rank <= 10
ORDER BY Rank;
