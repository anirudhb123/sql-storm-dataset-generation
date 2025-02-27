WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS rn,
        COUNT(*) OVER (PARTITION BY p.PostTypeId) AS total_posts
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
),
TopPosts AS (
    SELECT 
        r.Id,
        r.Title,
        r.Score,
        r.CreationDate,
        r.rn,
        r.total_posts
    FROM 
        RankedPosts r
    WHERE 
        r.rn <= 5
),
PostDetails AS (
    SELECT 
        tp.*, 
        u.DisplayName AS OwnerDisplayName,
        COALESCE(CAST(COUNT(c.Id) AS INT), 0) AS CommentCount,
        COALESCE(MAX(v.BountyAmount), 0) AS MaxBounty
    FROM 
        TopPosts tp
    LEFT JOIN 
        Users u ON tp.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON tp.Id = c.PostId
    LEFT JOIN 
        Votes v ON tp.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    GROUP BY 
        tp.Id, u.DisplayName
)
SELECT 
    pd.Title,
    pd.OwnerDisplayName,
    pd.Score,
    pd.CommentCount,
    pd.MaxBounty,
    COALESCE(pht.Name, 'No History') AS PostHistoryType,
    COUNT(h.Id) AS HistoryCount
FROM 
    PostDetails pd
LEFT JOIN 
    PostHistory h ON pd.Id = h.PostId
LEFT JOIN 
    PostHistoryTypes pht ON h.PostHistoryTypeId = pht.Id 
WHERE 
    pd.Score > 10 
GROUP BY 
    pd.Title, pd.OwnerDisplayName, pd.Score, pd.CommentCount, pd.MaxBounty, pht.Name
ORDER BY 
    pd.Score DESC, pd.CommentCount DESC;

WITH UserReputation AS (
    SELECT 
        Id, 
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        Users
),
BadgeStats AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges
    FROM 
        Badges
    GROUP BY 
        UserId
)
SELECT 
    u.DisplayName,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    COALESCE(b.GoldBadges, 0) AS GoldBadges,
    ur.Reputation,
    ur.ReputationRank
FROM 
    Users u
LEFT JOIN 
    BadgeStats b ON u.Id = b.UserId
JOIN 
    UserReputation ur ON u.Id = ur.Id
WHERE 
    ur.Reputation > 1000
ORDER BY 
    ur.ReputationRank;
