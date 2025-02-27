WITH UserStats AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
PostActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        AVG(p.Score) AS AverageScore
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.OwnerUserId
),
TopUsers AS (
    SELECT 
        us.Id,
        us.DisplayName,
        us.Reputation,
        us.TotalBounty,
        us.TotalBadges,
        us.TotalPosts,
        pu.PostCount,
        pu.CommentCount,
        pu.AverageScore,
        RANK() OVER (ORDER BY us.Reputation DESC, us.TotalBounty DESC) AS ReputationRank
    FROM UserStats us
    JOIN PostActivity pu ON us.Id = pu.OwnerUserId
)

SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalPosts,
    tu.TotalBadges,
    tu.TotalBounty,
    tu.PostCount,
    tu.CommentCount,
    tu.AverageScore
FROM TopUsers tu
WHERE tu.ReputationRank <= 10
ORDER BY tu.Reputation DESC, tu.TotalPosts DESC;

SELECT 
    p.Title,
    p.ViewCount,
    p.AnswerCount,
    p.AcceptedAnswerId
FROM Posts p
WHERE p.Id IN (
    SELECT RelatedPostId 
    FROM PostLinks 
    WHERE PostId IN (
        SELECT Id FROM Posts 
        WHERE Title ILIKE '%SQL%' 
        AND CreationDate >= NOW() - INTERVAL '2 years'
    )
)
ORDER BY p.ViewCount DESC
LIMIT 5;

SELECT 
    DISTINCT u.DisplayName, 
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
FROM Users u
LEFT JOIN Votes v ON u.Id = v.UserId
WHERE u.Reputation > 1000
GROUP BY u.DisplayName
HAVING COUNT(DISTINCT v.Id) > 10;

SELECT 
    p.Title,
    COUNT(c.Id) AS CommentCount,
    AVG(p.Score) OVER (PARTITION BY p.OwnerUserId) AS AvgScoreByUser
FROM Posts p
LEFT JOIN Comments c ON p.Id = c.PostId
WHERE p.CreationDate >= '2023-01-01' 
GROUP BY p.Title
HAVING AvgScoreByUser > 5
ORDER BY CommentCount DESC;
