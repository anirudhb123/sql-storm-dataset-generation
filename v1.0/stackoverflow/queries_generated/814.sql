WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM Users u
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON c.UserId = u.Id
    LEFT JOIN Votes v ON v.UserId = u.Id
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        ua.UpVotes,
        ua.DownVotes,
        ua.PostCount,
        ua.CommentCount,
        ua.UserRank
    FROM UserActivity ua
    WHERE ua.UserRank <= 10
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Author,
        p.ViewCount,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= NOW() - INTERVAL '1 month'
)
SELECT 
    tu.DisplayName AS TopUserName,
    tu.Reputation AS TopUserReputation,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS PostCreationDate,
    rp.Author AS PostAuthor,
    rp.ViewCount AS PostViewCount,
    rp.CommentCount AS PostCommentCount
FROM TopUsers tu
LEFT JOIN RecentPosts rp ON tu.UserId = rp.Author
WHERE rp.PostRank = 1 OR rp.PostRank IS NULL
ORDER BY tu.Reputation DESC, rp.CreationDate DESC;
