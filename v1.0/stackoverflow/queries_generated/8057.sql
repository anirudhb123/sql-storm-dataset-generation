WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
PostDistribution AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score IS NOT NULL THEN 1 ELSE 0 END) AS ScoredPosts
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
TopUsers AS (
    SELECT 
        ua.UserId,
        SUM(ua.Reputation) AS TotalReputation,
        SUM(ua.MemoryIssue) AS TotalMemoryIssue,
        RANK() OVER (ORDER BY SUM(ua.Reputation) DESC) AS UserRank
    FROM 
        UserStats ua
    WHERE 
        ua.Reputation > 0
    GROUP BY 
        ua.UserId
)
SELECT 
    us.UserId,
    us.Reputation,
    us.BadgeCount,
    us.UpVotes,
    us.DownVotes,
    us.TotalViews,
    pd.PostType,
    pd.TotalPosts,
    pd.ScoredPosts,
    tu.TotalReputation,
    tu.UserRank
FROM 
    UserStats us
JOIN 
    PostDistribution pd ON us.UserId = pd.PostType
JOIN 
    TopUsers tu ON us.UserId = tu.UserId
ORDER BY 
    us.Reputation DESC, us.BadgeCount DESC, us.TotalViews DESC;
