
WITH UserStatistics AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.Reputation, u.Views, u.UpVotes, u.DownVotes
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        Views,
        UpVotes,
        DownVotes,
        PostCount,
        TotalBountyAmount,
        @rank := @rank + 1 AS Rank
    FROM UserStatistics, (SELECT @rank := 0) AS r
    ORDER BY PostCount DESC, Reputation DESC
)
SELECT 
    UserId,
    Reputation,
    Views,
    UpVotes,
    DownVotes,
    PostCount,
    TotalBountyAmount
FROM TopUsers
WHERE Rank <= 10;
