WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsArray,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        LATERAL unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tagName ON TRUE
    LEFT JOIN
        Tags t ON t.TagName = tagName
    GROUP BY
        p.Id, u.DisplayName
),

TopPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        rp.TagsArray
    FROM
        RankedPosts rp
    WHERE
        rp.OwnerPostRank = 1
)

SELECT
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.CreationDate,
    tp.Score,
    tp.OwnerDisplayName,
    ARRAY_TO_STRING(tp.TagsArray, ', ') AS Tags,
    COALESCE(pht.ClosedCount, 0) AS ClosedPostCount,
    COALESCE(phf.FavoriteCount, 0) AS FavoritePostCount
FROM
    TopPosts tp
LEFT JOIN (
    SELECT
        ph.PostId,
        COUNT(*) AS ClosedCount
    FROM
        PostHistory ph
    WHERE
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY
        ph.PostId
) pht ON tp.PostId = pht.PostId
LEFT JOIN (
    SELECT
        p.Id AS PostId,
        COUNT(*) AS FavoriteCount
    FROM
        Votes v
    JOIN
        Posts p ON v.PostId = p.Id
    WHERE
        v.VoteTypeId = 5 -- Favorite
    GROUP BY
        p.Id
) phf ON tp.PostId = phf.PostId
ORDER BY
    tp.Score DESC, tp.ViewCount DESC
LIMIT 10;
