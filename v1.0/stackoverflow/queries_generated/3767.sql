WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.Rank = 1 THEN 1 ELSE 0 END) AS TopPostCount
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.TopPostCount,
    COALESCE(ub.BadgeNames, 'No Badges') AS Badges
FROM 
    TopUsers tu
LEFT JOIN 
    UserBadges ub ON tu.UserId = ub.UserId
WHERE 
    tu.TopPostCount > 0
ORDER BY 
    tu.TopPostCount DESC;
