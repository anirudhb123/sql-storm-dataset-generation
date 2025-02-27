WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(vote_count, 0)) AS TotalVotes,
        ROW_NUMBER() OVER (ORDER BY COUNT(p.Id) DESC) AS Rnk
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS vote_count 
        FROM Votes 
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        TotalVotes
    FROM UserStatistics
    WHERE Rnk <= 10
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM Posts p
    LEFT JOIN UNNEST(string_to_array(p.Tags, ',')) AS tag ON TRUE
    LEFT JOIN Tags t ON TRIM(tag) = t.TagName
    WHERE p.CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId
)
SELECT 
    tu.DisplayName AS TopUser,
    tu.Reputation,
    tu.PostCount,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    rp.Tags AS PostTags,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
FROM TopUsers tu
INNER JOIN RecentPosts rp ON tu.UserId = rp.OwnerUserId
LEFT JOIN Votes v ON v.PostId = rp.PostId
GROUP BY tu.DisplayName, tu.Reputation, tu.PostCount, rp.Title, rp.CreationDate, rp.Tags
ORDER BY tu.Reputation DESC, rp.CreationDate DESC;
