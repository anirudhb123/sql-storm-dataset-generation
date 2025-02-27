-- Performance benchmarking query to analyze the activity of users based on their posts, votes, and badges earned.
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    VoteCount,
    BadgeCount,
    TotalUpVotes,
    TotalDownVotes,
    (PostCount + VoteCount + BadgeCount) AS TotalActivity
FROM 
    UserActivity
ORDER BY 
    TotalActivity DESC;
