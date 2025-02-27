
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) 
    LEFT JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) AS tag
         FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON tag = t.TagName
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName, u.Reputation
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        ph.UserDisplayName AS EditorDisplayName,
        pht.Name AS ChangeType,
        ph.Text AS ChangeDetails
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
),
RankedPostHistories AS (
    SELECT 
        p.PostId,
        @row_number := IF(@current_post = p.PostId, @row_number + 1, 1) AS HistoryRank,
        @current_post := p.PostId,
        ph.HistoryDate,
        ph.EditorDisplayName,
        ph.ChangeType,
        ph.ChangeDetails
    FROM 
        RankedPosts p
    JOIN 
        PostHistoryData ph ON p.PostId = ph.PostId
    CROSS JOIN (SELECT @row_number := 0, @current_post := NULL) AS vars
    ORDER BY 
        p.PostId, ph.HistoryDate DESC
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.OwnerDisplayName,
    rp.OwnerReputation,
    rp.CommentCount,
    rp.VoteCount,
    rp.Tags,
    ph.HistoryDate,
    ph.EditorDisplayName,
    ph.ChangeType,
    ph.ChangeDetails
FROM 
    RankedPosts rp
LEFT JOIN 
    RankedPostHistories ph ON rp.PostId = ph.PostId AND ph.HistoryRank = 1 
ORDER BY 
    rp.VoteCount DESC, 
    rp.CommentCount DESC
LIMIT 10;
