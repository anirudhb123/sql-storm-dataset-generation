WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2020-01-01' AND p.ViewCount > 50
    GROUP BY 
        p.Id, u.DisplayName
),
RecentBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Date >= CURRENT_DATE - INTERVAL '365 days'
    GROUP BY 
        b.UserId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COALESCE(rb.BadgeNames, 'No Badges') AS RecentBadges,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        RecentBadges rb ON u.Id = rb.UserId
    WHERE 
        u.Reputation >= 100
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    tu.DisplayName AS TopUser,
    tu.RecentBadges
FROM 
    RankedPosts rp
LEFT JOIN 
    TopUsers tu ON rp.OwnerDisplayName = tu.DisplayName
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.CommentCount DESC, rp.UpVoteCount DESC;
