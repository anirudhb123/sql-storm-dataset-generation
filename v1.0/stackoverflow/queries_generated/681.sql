WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(year, -2, GETDATE()) 
        AND p.PostTypeId = 1
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.Views
    HAVING 
        SUM(b.Class) > 3
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > '2020-01-01'
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    CASE 
        WHEN ps.UpVotes IS NULL THEN 0 
        ELSE ps.UpVotes 
    END AS EffectiveUpVotes,
    CASE 
        WHEN ps.DownVotes IS NULL THEN 0 
        ELSE ps.DownVotes 
    END AS EffectiveDownVotes
FROM 
    RankedPosts rp
JOIN 
    TopUsers tu ON rp.OwnerUserId = tu.UserId
LEFT JOIN 
    PostStatistics ps ON rp.OwnerUserId = ps.OwnerUserId
WHERE 
    rp.rn = 1
ORDER BY 
    tu.Reputation DESC, rp.Score DESC
OPTION (RECOMPILE);
