
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
        ROW_NUMBER() OVER (PARTITION BY GROUP_CONCAT(t.TagName ORDER BY t.TagName SEPARATOR ',') ORDER BY p.Score DESC) AS TagRank
    FROM
        Posts p
    JOIN
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '<>', numbers.n), '<>', -1)) AS tag
         FROM Posts p
         JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '<>', '')) >= numbers.n - 1) AS tag ON TRUE
    JOIN
        Tags t ON t.TagName = tag
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
LIMIT 100;
