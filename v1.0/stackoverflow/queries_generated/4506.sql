WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostVoteCounts AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    up.DisplayName,
    up.Reputation,
    up.BadgeCount,
    up.GoldBadges,
    up.SilverBadges,
    up.BronzeBadges,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    COALESCE(pvc.UpVotes, 0) AS UpVoteCount,
    COALESCE(pvc.DownVotes, 0) AS DownVoteCount
FROM 
    RankedPosts rp
JOIN 
    UserReputation up ON rp.OwnerUserId = up.UserId
LEFT JOIN 
    PostVoteCounts pvc ON rp.PostId = pvc.PostId
WHERE 
    rp.rn = 1 -- Get the most recent question of each user
ORDER BY 
    up.Reputation DESC,
    rp.Score DESC
FETCH FIRST 10 ROWS ONLY;
