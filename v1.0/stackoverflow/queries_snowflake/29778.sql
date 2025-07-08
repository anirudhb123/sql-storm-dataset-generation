
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
        LISTAGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        LATERAL FLATTEN(input => SPLIT(SUBSTR(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS t(TagName) ON TRUE
    WHERE 
        p.PostTypeId IN (1, 2) 
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
    rp.Score > 5 
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC,
    rp.LastActivityDate DESC
LIMIT 100;
