
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(CAST(p.OwnerDisplayName AS CHAR), 'Community') AS OwnerDisplayName,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS EditHistoryCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) AS TagName
         FROM 
            (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION 
             SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers 
         INNER JOIN Posts p ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS t ON TRUE
    WHERE 
        p.PostTypeId = 1 AND p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerDisplayName
),
PostRankings AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Tags,
        rp.CommentCount,
        rp.EditHistoryCount,
        RANK() OVER (ORDER BY rp.Score DESC, rp.ViewCount DESC, rp.CreationDate ASC) AS PostRank
    FROM 
        RankedPosts rp
)
SELECT 
    pr.Id,
    pr.Title,
    pr.OwnerDisplayName,
    pr.CreationDate,
    pr.Score,
    pr.ViewCount,
    pr.Tags,
    pr.CommentCount,
    pr.EditHistoryCount,
    pr.PostRank
FROM 
    PostRankings pr
WHERE 
    pr.PostRank <= 10
ORDER BY 
    pr.PostRank;
