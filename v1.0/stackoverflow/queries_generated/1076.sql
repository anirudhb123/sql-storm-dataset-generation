WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        MAX(b.Date) AS LastBadgeDate,
        (SELECT COUNT(*) 
         FROM Posts p2 
         WHERE p2.OwnerUserId = u.Id 
           AND p2.CreationDate >= NOW() - INTERVAL '1 year') AS RecentPostsCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        UpVotes,
        DownVotes,
        LastBadgeDate,
        RecentPostsCount,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.UpVotes,
    tu.DownVotes,
    COALESCE(TO_CHAR(tu.LastBadgeDate, 'YYYY-MM-DD'), 'No Badges') AS BadgeDate,
    CASE 
        WHEN tu.RecentPostsCount > 10 THEN 'High Activity'
        WHEN tu.RecentPostsCount BETWEEN 5 AND 10 THEN 'Moderate Activity'
        ELSE 'Low Activity'
    END AS ActivityLevel
FROM 
    TopUsers tu
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.Rank;
