
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS TagsArray,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS tag_name
         FROM 
         (SELECT @rownum:=@rownum+1 AS n FROM 
                 (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) t1,
                 (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) t2,
                 (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) t3,
                 (SELECT @rownum:=0) r
         ) n) AS tag_name ON TRUE
    LEFT JOIN 
        Tags t ON tag_name = t.TagName
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score
),
TopPosts AS (
    SELECT * 
    FROM RankedPosts
    WHERE Rank <= 5 
),
DetailedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        ph.UserDisplayName,
        ph.Comment,
        p.Title,
        p.Body,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13) 
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.TagsArray,
    ph.HistoryDate,
    ph.UserDisplayName AS HistoryUser,
    ph.Comment AS HistoryComment
FROM 
    TopPosts tp
LEFT JOIN 
    DetailedPostHistory ph ON tp.PostId = ph.PostId AND ph.HistoryRank = 1
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
