
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        @row_num := IF(@prev_owner = p.OwnerUserId, @row_num + 1, 1) AS RecentPostRank,
        @prev_owner := p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    CROSS JOIN (SELECT @row_num := 0, @prev_owner := NULL) AS vars
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
PostActivity AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryActionCount,
        GROUP_CONCAT(DISTINCT CONCAT(ph.CreationDate, ': ', ph.Comment) ORDER BY ph.CreationDate SEPARATOR '; ') AS ActionDetails
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 14, 15)
    GROUP BY 
        ph.PostId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        @reputation_rank := @reputation_rank + 1 AS ReputationRank
    FROM 
        Users u
    CROSS JOIN (SELECT @reputation_rank := 0) AS r
    ORDER BY 
        u.Reputation DESC
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.RecentPostRank,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    pa.HistoryActionCount,
    pa.ActionDetails,
    CASE 
        WHEN rp.GoldBadges > 0 THEN 'Gold Badge Holder'
        WHEN rp.SilverBadges > 0 THEN 'Silver Badge Holder'
        ELSE 'No Badges'
    END AS BadgeStatus,
    ur.Reputation,
    ur.ReputationRank
FROM 
    RankedPosts rp
LEFT JOIN 
    PostActivity pa ON pa.PostId = rp.PostId
JOIN 
    UserReputation ur ON ur.UserId = rp.OwnerUserId
WHERE 
    (rp.CommentCount > 0 OR rp.UpVoteCount > 0)
    AND rp.RecentPostRank = 1
ORDER BY 
    rp.CreationDate DESC, ur.Reputation DESC
LIMIT 100;
