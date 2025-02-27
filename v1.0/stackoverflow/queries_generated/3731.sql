WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(b.Class = 1)::int, 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2)::int, 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3)::int, 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostVoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId = 4 THEN 1 ELSE 0 END) AS OffensiveVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    ur.Reputation,
    ur.GoldBadges,
    ur.SilverBadges,
    ur.BronzeBadges,
    COALESCE(pvs.UpVotes, 0) AS UpVotes,
    COALESCE(pvs.DownVotes, 0) AS DownVotes,
    COALESCE(pvs.OffensiveVotes, 0) AS OffensiveVotes,
    rp.UserPostRank
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.Title LIKE '%' || u.DisplayName || '%' 
LEFT JOIN 
    UserReputation ur ON u.Id = ur.UserId
LEFT JOIN 
    PostVoteSummary pvs ON rp.PostId = pvs.PostId
WHERE 
    rp.UserPostRank = 1
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 50;
