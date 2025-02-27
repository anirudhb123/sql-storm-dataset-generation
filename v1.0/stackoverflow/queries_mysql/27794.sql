
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.Score,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (
            SELECT 
                p.Id,
                SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
            FROM 
                Posts p
            INNER JOIN 
                (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
                 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 
                 UNION ALL SELECT 10) numbers 
            ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
        ) t ON p.Id = t.Id
    WHERE 
        p.CreationDate >= CURDATE() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.ViewCount, p.Score
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
