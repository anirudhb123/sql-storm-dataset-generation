WITH RankedPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS Upvotes,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS Downvotes,
        COALESCE(SUM(v.VoteTypeId = 10) OVER (PARTITION BY p.Id), 0) AS Deletions,
        COALESCE(SUM(c.Id) OVER (PARTITION BY p.Id), 0) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS Rank
    FROM
        Posts p
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    WHERE
        p.PostTypeId = 1 AND -- Only Questions
        p.CreationDate >= NOW() - INTERVAL '1 month' -- Only posts created in the last month
),

TopPosts AS (
    SELECT
        Id,
        Title,
        CreationDate,
        ViewCount,
        Score,
        Upvotes,
        Downvotes,
        Deletions,
        CommentCount
    FROM
        RankedPosts
    WHERE
        Rank <= 10
)

SELECT
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.Upvotes,
    tp.Downvotes,
    tp.Deletions,
    tp.CommentCount,
    ROUND((tp.Upvotes::decimal / NULLIF(tp.Upvotes + tp.Downvotes, 0)) * 100, 2) AS UpvotePercentage
FROM
    TopPosts tp
ORDER BY
    tp.Score DESC, tp.ViewCount DESC;
