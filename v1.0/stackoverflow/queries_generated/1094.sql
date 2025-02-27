WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS Upvotes,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
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
PostActivity AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS ChangeCount,
        MAX(ph.CreationDate) AS LastChangeDate,
        STRING_AGG(DISTINCT ph.Comment, ', ') AS ChangeComments
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= DATEADD(month, -6, GETDATE())
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.Upvotes,
    rp.Downvotes,
    us.DisplayName AS OwnerName,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    pa.ChangeCount,
    pa.LastChangeDate,
    COALESCE(pa.ChangeComments, 'No changes') AS ChangeComments
FROM 
    RankedPosts rp
JOIN 
    Users u ON u.Id = p.OwnerUserId
JOIN 
    UserStats us ON us.UserId = u.Id
LEFT JOIN 
    PostActivity pa ON pa.PostId = rp.PostId
WHERE 
    rp.Rank = 1
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate ASC;
