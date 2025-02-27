
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        @rownum := IF(@prevPostTypeId = p.PostTypeId, @rownum + 1, 1) AS Rank,
        GROUP_CONCAT(t.TagName) AS Tags,
        @prevPostTypeId := p.PostTypeId
    FROM 
        Posts p 
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (
            SELECT DISTINCT 
                NULL AS tag_id 
            UNION ALL 
            SELECT 
                SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1) AS tag_id 
            FROM 
                (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
                 SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
                 SELECT 9 UNION ALL SELECT 10) numbers 
            WHERE 
                CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1
        ) AS tag_id ON tag_id IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag_id.tag_id
    CROSS JOIN 
        (SELECT @rownum := 0, @prevPostTypeId := NULL) r
    WHERE 
        p.CreationDate > NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.AnswerCount, u.DisplayName, p.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        ViewCount, 
        Score, 
        AnswerCount,
        OwnerDisplayName,
        Tags
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.Score,
    tp.AnswerCount,
    tp.OwnerDisplayName,
    tp.Tags
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;
