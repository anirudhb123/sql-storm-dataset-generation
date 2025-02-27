
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(NULLIF(TRIM(tag), '')) AS TagCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        (SELECT TRIM(tag) AS tag FROM 
            (SELECT SUBSTRING(p.Tags, 2, CHAR_LENGTH(p.Tags) - 2) AS tag_list FROM Posts p) AS t
            CROSS JOIN (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(tag_list, '<>', numbers.n), '<>', -1)) AS tag 
                        FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
                              UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 
                              UNION ALL SELECT 10) numbers 
                        WHERE CHAR_LENGTH(tag_list) - CHAR_LENGTH(REPLACE(tag_list, '<>', '')) >= n - 1) AS tag) 
        ) AS tag ON TRUE
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, u.Reputation, p.PostTypeId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.TagCount,
    rp.OwnerDisplayName,
    rp.OwnerReputation,
    COALESCE(ph.Comment, 'No changes made') AS LastModificationComment,
    ph.CreationDate AS LastModificationDate
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistory ph ON rp.PostId = ph.PostId 
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.OwnerDisplayName, 
    rp.Score DESC;
