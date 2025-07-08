
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
        LISTAGG(DISTINCT t.TagName, ', ') WITHIN GROUP (ORDER BY t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) 
    LEFT JOIN 
        (SELECT TRIM(tag) AS tag FROM LATERAL FLATTEN(INPUT => SPLIT(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '> <'))) AS tag) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON tag.tag = t.TagName
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
        ROW_NUMBER() OVER (PARTITION BY p.PostId ORDER BY ph.HistoryDate DESC) AS HistoryRank,
        ph.HistoryDate,
        ph.EditorDisplayName,
        ph.ChangeType,
        ph.ChangeDetails
    FROM 
        RankedPosts p
    JOIN 
        PostHistoryData ph ON p.PostId = ph.PostId
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
