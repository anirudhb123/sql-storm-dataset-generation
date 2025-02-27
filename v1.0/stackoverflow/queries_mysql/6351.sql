
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        t.TagName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1) AS TagName
         FROM Posts p
         INNER JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
                      UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 
                      UNION ALL SELECT 10) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1) t ON TRUE
    WHERE 
        p.CreationDate > NOW() - INTERVAL 1 YEAR
),
TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp 
    WHERE 
        rp.Rank <= 5
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Score,
        tp.ViewCount,
        tp.OwnerDisplayName,
        GROUP_CONCAT(DISTINCT tp.TagName ORDER BY tp.TagName SEPARATOR ', ') AS Tags
    FROM 
        TopPosts tp
    GROUP BY 
        tp.PostId, tp.Title, tp.Score, tp.ViewCount, tp.OwnerDisplayName
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Score,
    pd.ViewCount,
    pd.OwnerDisplayName,
    pd.Tags,
    bh.Name AS BadgeName,
    COUNT(c.Id) AS CommentCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
FROM 
    PostDetails pd
LEFT JOIN 
    Comments c ON pd.PostId = c.PostId
LEFT JOIN 
    Badges bh ON bh.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = pd.PostId)
LEFT JOIN 
    Votes v ON pd.PostId = v.PostId
GROUP BY 
    pd.PostId, pd.Title, pd.Score, pd.ViewCount, pd.OwnerDisplayName, pd.Tags, bh.Name
ORDER BY 
    pd.ViewCount DESC, pd.Score DESC;
