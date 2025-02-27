
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS tagId ON tagId.value IS NOT NULL
    LEFT JOIN
        Tags t ON t.Id = tagId.value
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.LastActivityDate, p.Score
),
PostVotes AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostHistoryDetails AS (
    SELECT 
        p.Id AS PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 2 THEN ph.CreationDate END) AS InitialEditDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 4 THEN ph.CreationDate END) AS LastEditDate,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.CreationDate END) AS ClosureDate
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.LastActivityDate,
    rp.Score,
    rp.CommentCount,
    pv.UpVotes,
    pv.DownVotes,
    hd.InitialEditDate,
    hd.LastEditDate,
    hd.ClosureDate,
    CASE WHEN hd.ClosureDate IS NOT NULL THEN 1 ELSE 0 END AS IsClosed,
    STRING_AGG(DISTINCT tag, ', ') AS AllTags
FROM 
    RankedPosts rp
JOIN 
    PostVotes pv ON rp.PostId = pv.PostId
JOIN 
    PostHistoryDetails hd ON rp.PostId = hd.PostId
CROSS APPLY 
    STRING_SPLIT(rp.Tags, ', ') AS tag
WHERE 
    rp.LastActivityDate > DATEADD(MONTH, -1, CAST('2024-10-01 12:34:56' AS DATETIME))
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.LastActivityDate, 
    rp.Score, rp.CommentCount, pv.UpVotes, pv.DownVotes, 
    hd.InitialEditDate, hd.LastEditDate, hd.ClosureDate
ORDER BY 
    rp.Score DESC, rp.LastActivityDate DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
