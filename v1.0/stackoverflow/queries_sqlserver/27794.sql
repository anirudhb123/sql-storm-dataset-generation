
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.Score,
        STRING_AGG(DISTINCT t.TagName, ',') AS Tags,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    OUTER APPLY (
        SELECT 
            value AS TagName
        FROM 
            STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><')
    ) t
    WHERE 
        p.CreationDate >= CAST('2024-10-01' AS DATE) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.ViewCount, p.Score, p.PostTypeId
),

UserEngagement AS (
    SELECT 
        p.OwnerUserId,
        COUNT(v.Id) AS VoteCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.OwnerUserId
)

SELECT 
    rp.Title,
    rp.OwnerDisplayName,
    rp.ViewCount,
    rp.Score,
    rp.Tags,
    ue.VoteCount,
    ue.CommentCount,
    ue.GoldBadges,
    ue.SilverBadges,
    ue.BronzeBadges
FROM 
    RankedPosts rp
JOIN 
    UserEngagement ue ON rp.PostId = ue.OwnerUserId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.PostId, ue.VoteCount DESC;
