
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.Body,
        p.Tags,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY STRING_AGG(t.TagName, ',') ORDER BY p.Score DESC) AS TagRank
    FROM
        Posts p
    CROSS APPLY STRING_SPLIT(p.Tags, '<>') AS tag
    JOIN
        Tags t ON t.TagName = tag.value
    WHERE
        p.PostTypeId = 1  
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.LastActivityDate, p.Body, p.Tags, p.Score, p.ViewCount
)
SELECT
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.LastActivityDate,
    rp.Body,
    rp.Tags,
    rp.Score,
    rp.ViewCount,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVoteCount,  
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) AS DownVoteCount  
FROM
    RankedPosts rp
WHERE
    rp.TagRank = 1  
ORDER BY
    rp.Score DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
