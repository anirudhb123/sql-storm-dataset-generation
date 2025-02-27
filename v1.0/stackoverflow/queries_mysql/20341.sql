
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        @row_number := IF(@current_user_id = p.OwnerUserId, @row_number + 1, 1) AS UserPostRank,
        @current_user_id := p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId,
        (SELECT @current_user_id := NULL, @row_number := 0) AS vars
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadgeCount,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadgeCount,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(DISTINCT pht.Name ORDER BY pht.Name) AS HistoryTypes,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    up.UserId,
    up.Reputation,
    up.GoldBadgeCount,
    up.SilverBadgeCount,
    up.BronzeBadgeCount,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.UserPostRank,
    rp.CommentCount,
    COALESCE(phd.HistoryTypes, 'No history') AS PostHistory,
    phd.LastHistoryDate,
    rp.UpVoteCount,
    rp.DownVoteCount
FROM 
    UserReputation up
JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE 
    (up.Reputation > 100 AND rp.UserPostRank <= 5)
    OR (rp.Score >= 10 AND rp.CommentCount > 5 AND phd.LastHistoryDate IS NOT NULL)
ORDER BY 
    up.Reputation DESC, 
    rp.Score DESC;
