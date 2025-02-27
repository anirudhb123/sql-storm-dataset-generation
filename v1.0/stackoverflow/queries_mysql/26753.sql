
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        @row_num := IF(@prev_owner = p.OwnerUserId, @row_num + 1, 1) AS PostRank,
        @prev_owner := p.OwnerUserId,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) TagName
         FROM 
         (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
          SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
          SELECT 9 UNION ALL SELECT 10) numbers
         WHERE CHAR_LENGTH(p.Tags)
         -CHAR_LENGTH(REPLACE(p.Tags, '><', ''))>=numbers.n-1) AS tag ON TRUE
    JOIN 
        Tags t ON t.TagName = tag.TagName
    CROSS JOIN (SELECT @row_num := 0, @prev_owner := '') r
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Body, p.ViewCount, p.Score, p.CreationDate
),
FilteredRankedPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        ViewCount,
        Score,
        CreationDate,
        OwnerDisplayName,
        Tags
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5  
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        p.Title AS CurrentTitle,
        p.Body AS CurrentBody,
        p.Tags AS CurrentTags,
        ph.Comment AS EditComment
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  
)

SELECT 
    frp.PostId,
    frp.Title,
    frp.Body,
    frp.ViewCount,
    frp.Score,
    frp.CreationDate,
    frp.OwnerDisplayName,
    frp.Tags,
    PHD.HistoryDate,
    PHD.CurrentTitle,
    PHD.CurrentBody,
    PHD.CurrentTags,
    PHD.EditComment
FROM 
    FilteredRankedPosts frp
LEFT JOIN 
    PostHistoryData PHD ON frp.PostId = PHD.PostId
ORDER BY 
    frp.Score DESC, 
    frp.ViewCount DESC, 
    frp.CreationDate DESC;
