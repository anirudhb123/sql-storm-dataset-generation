
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.LastActivityDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS AvgUpVotes,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) TagName
         FROM 
         (
            SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
            UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
            UNION ALL SELECT 9 UNION ALL SELECT 10
         ) numbers 
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
        ) t ON TRUE
    WHERE 
        p.PostTypeId IN (1, 2) /* Considering only Questions and Answers */
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.LastActivityDate, u.DisplayName
), 

PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    rp.LastActivityDate,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.AvgUpVotes,
    rp.Tags,
    ph.EditCount,
    ph.LastEditDate,
    ph.ClosedDate
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryAnalysis ph ON rp.PostId = ph.PostId
WHERE 
    rp.Score > 5 /* Filter for highly scored posts */
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC,
    rp.LastActivityDate DESC
LIMIT 100; 
