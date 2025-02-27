
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        @row_number := IF(@prev_tag = p.Tags, @row_number + 1, 1) AS Rank,
        @prev_tag := p.Tags,
        (SELECT GROUP_CONCAT(b.Name SEPARATOR ', ') 
         FROM Badges b 
         WHERE b.UserId = p.OwnerUserId) AS OwnerBadges,
        (SELECT COUNT(DISTINCT c.Id) 
         FROM Comments c 
         WHERE c.PostId = p.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    CROSS JOIN (SELECT @row_number := 0, @prev_tag := '') AS vars
    WHERE 
        p.PostTypeId = 1 
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.Score,
    rp.OwnerDisplayName,
    rp.Reputation,
    rp.OwnerBadges,
    rp.CommentCount
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 3 
ORDER BY 
    rp.CreationDate DESC
LIMIT 50;
