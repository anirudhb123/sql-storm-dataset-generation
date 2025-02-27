WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(DISTINCT p.Id) AS PostCount, 
        SUM(COALESCE(v.Value, 0)) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount, 
        TotalVotes, 
        UpVotes, 
        DownVotes,
        DENSE_RANK() OVER (ORDER BY TotalVotes DESC) AS Rank
    FROM 
        UserEngagement
)
SELECT 
    t.UserId,
    t.DisplayName,
    t.PostCount,
    t.TotalVotes,
    t.UpVotes,
    t.DownVotes,
    COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
    COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
    COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
FROM 
    TopUsers t
LEFT JOIN 
    Badges b ON t.UserId = b.UserId
WHERE 
    t.Rank <= 10
GROUP BY 
    t.UserId, t.DisplayName, t.PostCount, t.TotalVotes, t.UpVotes, t.DownVotes
ORDER BY 
    t.TotalVotes DESC;
