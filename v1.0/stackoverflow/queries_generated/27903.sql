WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        RANK() OVER (ORDER BY p.Score DESC, p.CreationDate DESC) AS RankScore
    FROM
        Posts p
    INNER JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Badges b ON b.UserId = u.Id
    WHERE
        p.PostTypeId = 1 -- Only questions
    GROUP BY
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        rp.BadgeCount
    FROM
        RankedPosts rp
    WHERE
        rp.RankScore <= 10
),
PostTags AS (
    SELECT
        tp.PostId,
        STRING_AGG(TRIM(UNNEST(string_to_array(tp.Tags, '><'))), ', ') AS TagsList
    FROM
        TopPosts tp
    GROUP BY
        tp.PostId
)
SELECT
    tp.PostId,
    tp.Title,
    pt.TagsList,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.Score,
    tp.CommentCount,
    tp.BadgeCount
FROM
    TopPosts tp
JOIN
    PostTags pt ON tp.PostId = pt.PostId
ORDER BY
    tp.Score DESC, tp.CreationDate DESC;
