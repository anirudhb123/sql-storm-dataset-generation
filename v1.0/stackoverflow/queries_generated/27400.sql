WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        pt.Name AS PostType,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.CreationDate >= '2023-01-01' -- Filter for posts created in 2023
)

SELECT
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.PostType,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    rp.Tags,
    pt.Name AS PostHistoryType,
    COUNT(ph.Id) AS HistoryCount
FROM
    RankedPosts rp
LEFT JOIN
    PostHistory ph ON rp.PostId = ph.PostId
GROUP BY
    rp.PostId, rp.Title, rp.Body, rp.PostType, rp.CreationDate, rp.ViewCount, rp.Score, rp.OwnerDisplayName, rp.Tags, pt.Name
HAVING
    PostRank <= 3 -- Top 3 posts per type
ORDER BY
    rp.PostType,
    rp.Score DESC,
    rp.ViewCount DESC;
