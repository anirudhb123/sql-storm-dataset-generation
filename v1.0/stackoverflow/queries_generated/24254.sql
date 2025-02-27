WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.UpVotes > p.DownVotes THEN 1 ELSE 0 END) AS PositiveVotes,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPosts,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        PositiveVotes,
        PopularPosts,
        ReputationRank,
        ROW_NUMBER() OVER (PARTITION BY ReputationRank ORDER BY TotalPosts DESC) AS RankWithinReputation
    FROM UserStats
),
CommentsMeta AS (
    SELECT 
        c.UserId,
        COUNT(c.Id) AS CommentCount,
        AVG(LENGTH(c.Text)) AS AvgCommentLength,
        MAX(c.Score) AS MaxCommentScore,
        MIN(CASE WHEN c.CreationDate < NOW() - INTERVAL '1 year' THEN c.Score ELSE NULL END) AS OldestCommentScore
    FROM Comments c
    GROUP BY c.UserId
)

SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    tu.PositiveVotes,
    tu.PopularPosts,
    cm.CommentCount,
    cm.AvgCommentLength,
    cm.MaxCommentScore,
    CASE 
        WHEN tu.TotalPosts = 0 THEN 'No Activity'
        WHEN tu.TotalQuestions > tu.TotalAnswers THEN 'More Questions'
        ELSE 'Balanced Activity'
    END AS ActivityStatus,
    COALESCE(NULLIF(cm.OldestCommentScore, -1), 'No Old Comments') AS OldestCommentStatus
FROM TopUsers tu
LEFT JOIN CommentsMeta cm ON tu.UserId = cm.UserId
WHERE tu.RankWithinReputation <= 5
ORDER BY tu.ReputationRank, tu.TotalPosts DESC;
