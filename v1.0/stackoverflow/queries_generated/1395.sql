WITH UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.VoteCount, 0)) AS TotalVotes,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) v ON v.PostId IN (
        SELECT DISTINCT Id 
        FROM Posts 
        WHERE OwnerUserId = u.Id
    )
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    GROUP BY u.Id, u.DisplayName, u.Reputation
), TopUsers AS (
    SELECT * 
    FROM UserStats 
    WHERE ReputationRank <= 10
), RecentPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.AnswerCount, 
        p.ViewCount, 
        COALESCE(c.CommentCount, 0) AS CommentCount
    FROM Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON c.PostId = p.Id
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
), PostDetails AS (
    SELECT 
        p.UserId, 
        COUNT(pl.RelatedPostId) AS RelatedPostCount
    FROM Posts p
    LEFT JOIN PostLinks pl ON pl.PostId = p.Id
    WHERE p.PostTypeId IN (1, 2)
    GROUP BY p.UserId
)
SELECT 
    tu.DisplayName, 
    tu.Reputation, 
    tu.PostCount, 
    tu.TotalVotes, 
    rp.PostId, 
    rp.Title, 
    rp.CreationDate, 
    rp.CommentCount, 
    COALESCE(pd.RelatedPostCount, 0) AS RelatedPostCount
FROM TopUsers tu
JOIN RecentPosts rp ON rp.UserId = tu.UserId
LEFT JOIN PostDetails pd ON pd.UserId = tu.UserId
ORDER BY tu.Reputation DESC, rp.ViewCount DESC
LIMIT 50;
