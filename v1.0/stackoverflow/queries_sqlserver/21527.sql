
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS ScoreRank,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS UpVoteCount,
        COUNT(v.Id) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId AND c.UserId IS NOT NULL
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, CAST('2024-10-01' AS DATE))
    GROUP BY 
        p.Id, p.Title, p.PostTypeId, p.CreationDate, p.Score, p.ViewCount
),

PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13, 14, 15) 
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS GoldBadges,
        COUNT(DISTINCT b.Id) AS SilverBadges,
        COUNT(DISTINCT b.Id) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        b.Class IN (1, 2, 3)
    GROUP BY 
        u.Id, u.Reputation
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.PostTypeId,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    phd.UserId AS LastModifierId,
    phd.Comment AS LastActionComment,
    phd.CreationDate AS LastActionDate,
    ur.Reputation AS UserReputation,
    ur.GoldBadges,
    ur.SilverBadges,
    ur.BronzeBadges,
    CASE 
        WHEN rp.ScoreRank <= 5 THEN 'Top Posts'
        ELSE 'Regular Posts'
    END AS PostCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId AND phd.HistoryRank = 1
LEFT JOIN 
    UserReputation ur ON phd.UserId = ur.UserId
WHERE 
    (rp.Score >= 100 OR rp.CommentCount > 5)
    AND ur.Reputation IS NOT NULL
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC, rp.CreationDate ASC;
