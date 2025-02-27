WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS rn
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    WHERE
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, p.PostTypeId
),
TopPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerName,
        rp.CommentCount
    FROM
        RankedPosts rp
    WHERE
        rp.rn <= 10
),
PostDetails AS (
    SELECT
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        tp.OwnerName,
        tp.CommentCount,
        JSON_AGG(
            JSON_BUILD_OBJECT('Id', c.Id, 'Text', c.Text, 'CreationDate', c.CreationDate, 'UserDisplayName', c.UserDisplayName)
        ) AS Comments
    FROM
        TopPosts tp
    LEFT JOIN
        Comments c ON tp.PostId = c.PostId
    GROUP BY
        tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.OwnerName, tp.CommentCount
)
SELECT
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.OwnerName,
    pd.CommentCount,
    pd.Comments
FROM
    PostDetails pd
ORDER BY
    pd.Score DESC, pd.CreationDate DESC;
