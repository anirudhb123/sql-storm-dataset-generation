WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        SUM(CASE WHEN p.PostTypeId = 1 THEN p.AnswerCount ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalQuestions
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        BadgeCount,
        TotalUpvotes,
        TotalDownvotes,
        TotalAnswers,
        TotalQuestions,
        DENSE_RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserStats
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM Posts p
    LEFT JOIN Tags t ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    WHERE p.PostTypeId = 1
    GROUP BY p.Id, p.Title, p.Body, p.Score, p.ViewCount, p.AnswerCount, p.CreationDate
    ORDER BY p.Score DESC
    LIMIT 5
)
SELECT 
    u.DisplayName AS User,
    u.Reputation,
    u.BadgeCount,
    u.TotalUpvotes,
    u.TotalDownvotes,
    u.TotalAnswers,
    u.TotalQuestions,
    pp.Title AS PopularPostTitle,
    pp.Score AS PopularPostScore,
    pp.ViewCount AS PopularPostViews,
    pp.CreationDate AS PopularPostDate,
    pp.Tags AS PopularPostTags,
    tu.Rank AS UserRank
FROM TopUsers tu
JOIN Users u ON tu.UserId = u.Id
JOIN PopularPosts pp ON u.TotalAnswers > 0
ORDER BY tu.Rank, pp.Score DESC;
