WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Owner,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    COUNT(c.Id) AS CommentCount,
    MAX(ph.CreationDate) AS LastEditDate,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    RankedPosts rp
LEFT JOIN 
    Comments c ON c.PostId = rp.PostId
LEFT JOIN 
    PostHistory ph ON ph.PostId = rp.PostId AND ph.PostHistoryTypeId IN (4, 5) -- Edit Title and Edit Body
LEFT JOIN 
    Votes v ON v.PostId = rp.PostId
LEFT JOIN 
    UNNEST(string_to_array(rp.Tags, ',')) AS tag(tagName) ON TRUE
LEFT JOIN 
    Tags t ON t.Id = tag.tagName::int
WHERE 
    rp.Rank <= 10
GROUP BY 
    rp.PostId, rp.Title, rp.Owner, rp.CreationDate, rp.Score, rp.ViewCount, rp.AnswerCount
ORDER BY 
    rp.Score DESC;
