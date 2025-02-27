
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounties,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        CommentCount,
        TotalBounties,
        TotalUpVotes,
        TotalDownVotes,
        @rank := @rank + 1 AS Rank
    FROM UserActivity, (SELECT @rank := 0) r
    ORDER BY PostCount DESC
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    CommentCount,
    TotalBounties,
    TotalUpVotes,
    TotalDownVotes
FROM TopUsers
WHERE Rank <= 10;
