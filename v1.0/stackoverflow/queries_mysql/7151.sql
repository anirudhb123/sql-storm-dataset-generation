
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Score,
        @row_number := IF(@current_post_type = p.PostTypeId, @row_number + 1, 1) AS Rank,
        @current_post_type := p.PostTypeId
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    CROSS JOIN 
        (SELECT @row_number := 0, @current_post_type := NULL) AS vars
    WHERE 
        p.CreationDate >= TIMESTAMP('2024-10-01 12:34:56') - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, u.DisplayName, u.Reputation, p.PostTypeId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.OwnerReputation,
    rp.CommentCount,
    rp.Score
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Score DESC, rp.CommentCount DESC;
