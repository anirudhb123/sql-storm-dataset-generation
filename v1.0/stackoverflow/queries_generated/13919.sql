-- Performance Benchmarking Query
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(v.Score) AS TotalVoteScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        pt.Name AS PostType,
        COUNT(c.Id) AS CommentCount,
        SUM(v.Score) AS TotalVotes
    FROM Posts p
    LEFT JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, pt.Name
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.PostCount,
    ua.TotalBounty,
    ua.TotalVoteScore,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.PostType,
    ps.CommentCount,
    ps.TotalVotes
FROM UserActivity ua
JOIN PostStatistics ps ON ua.UserId = ps.OwnerUserId
ORDER BY ua.PostCount DESC, ua.TotalVoteScore DESC;
