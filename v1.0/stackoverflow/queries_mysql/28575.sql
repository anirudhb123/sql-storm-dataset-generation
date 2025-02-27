
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
        AND p.CreationDate > NOW() - INTERVAL 1 YEAR
)
SELECT
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    GROUP_CONCAT(DISTINCT t.TagName) AS AssociatedTags,
    ch.Comment AS LastEditComment,
    SUM(v.VoteTypeId = 2) AS UpVotes,
    SUM(v.VoteTypeId = 3) AS DownVotes
FROM
    RankedPosts rp
LEFT JOIN
    Tags t ON rp.Tags LIKE CONCAT('%', t.TagName, '%')
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
