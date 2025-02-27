
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        @row_number := IF(@owner_user_id = p.OwnerUserId, @row_number + 1, 1) AS ScoreRank,
        @owner_user_id := p.OwnerUserId,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    JOIN (SELECT @row_number := 0, @owner_user_id := NULL) r
    LEFT JOIN 
        (SELECT TRIM(BOTH '>' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '<', -1), '>', 1)) AS tag_name 
         FROM Posts p 
         WHERE p.CreationDate > DATE('2024-10-01') - INTERVAL 30 DAY) AS tag_name ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_name
    WHERE 
        p.CreationDate > DATE('2024-10-01') - INTERVAL 30 DAY
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        Tags
    FROM 
        RankedPosts
    WHERE 
        ScoreRank = 1
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.Tags,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation,
    COALESCE(b.BadgeCount, 0) AS BadgeCount
FROM 
    TopPosts tp
JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
LEFT JOIN (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount 
    FROM 
        Badges 
    GROUP BY 
        UserId
) b ON b.UserId = u.Id
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC
LIMIT 10;
