
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.PostTypeId = 1 
        AND p.CreationDate > DATEADD(YEAR, -1, '2024-10-01 12:34:56') 
)
SELECT
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    STRING_AGG(DISTINCT t.TagName, ',') AS AssociatedTags,
    ch.Comment AS LastEditComment,
    COUNT(CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVotes,
    COUNT(CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVotes
FROM
    RankedPosts rp
LEFT JOIN
    Tags t ON rp.Tags LIKE '%' + t.TagName + '%'
LEFT JOIN
    PostHistory ch ON rp.PostId = ch.PostId
LEFT JOIN
    Votes v ON rp.PostId = v.PostId
WHERE
    rp.Rank <= 5 
GROUP BY
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    ch.Comment
ORDER BY
    rp.Score DESC, rp.ViewCount DESC;
