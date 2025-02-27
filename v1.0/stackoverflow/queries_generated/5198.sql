WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        QuestionCount,
        AnswerCount,
        TotalViews,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY TotalPosts DESC) AS RankByPosts,
        RANK() OVER (ORDER BY TotalViews DESC) AS RankByViews
    FROM UserPostStats
),
UserBadges AS (
    SELECT 
        ub.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Badges b
    JOIN Users ub ON b.UserId = ub.Id
    GROUP BY ub.UserId
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.TotalPosts,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.TotalViews,
    tu.UpVotes,
    tu.DownVotes,
    ub.BadgeCount,
    tu.RankByPosts,
    tu.RankByViews
FROM TopUsers tu
JOIN UserBadges ub ON tu.UserId = ub.UserId
WHERE tu.RankByPosts <= 10
ORDER BY tu.RankByPosts, tu.TotalViews DESC;
