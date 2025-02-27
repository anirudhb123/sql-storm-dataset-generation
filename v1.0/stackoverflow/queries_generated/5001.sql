WITH UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        COUNT(DISTINCT p.Id) AS PostCount, 
        SUM(COALESCE(v.VoteValue, 0)) AS TotalVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId, 
            SUM(CASE 
                WHEN vt.Name = 'UpMod' THEN 1 
                WHEN vt.Name = 'DownMod' THEN -1 
                ELSE 0 
            END) AS VoteValue
        FROM Votes v
        JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        *, 
        ROW_NUMBER() OVER (ORDER BY Reputation DESC, TotalVotes DESC) AS Rank
    FROM UserReputation
    WHERE PostCount > 10
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        p.Score, 
        t.TagName AS MainTag,
        DATEDIFF(CURRENT_TIMESTAMP, p.CreationDate) AS DaysOld
    FROM Posts p
    JOIN Tags t ON p.Tags LIKE CONCAT('%<', t.TagName, '>') 
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
),
PostsWithComments AS (
    SELECT 
        rp.*, 
        COUNT(c.Id) AS CommentCount
    FROM RecentPosts rp
    LEFT JOIN Comments c ON rp.PostId = c.PostId
    GROUP BY rp.PostId, rp.Title, rp.CreationDate, rp.ViewCount, rp.Score, rp.MainTag, rp.DaysOld
)
SELECT 
    tu.DisplayName, 
    tu.Reputation, 
    tu.PostCount, 
    rp.PostId, 
    rp.Title, 
    rp.DaysOld, 
    rp.ViewCount, 
    rp.Score, 
    rp.CommentCount
FROM TopUsers tu
JOIN PostsWithComments rp ON tu.UserId = rp.OwnerUserId
WHERE tu.Rank <= 50
ORDER BY rp.ViewCount DESC, rp.Score DESC;
