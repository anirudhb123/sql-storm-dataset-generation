
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.ANSWERCOUNT,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(DAY, -30, '2024-10-01 12:34:56')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.ANSWERCOUNT, u.DisplayName
),
PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        pv.Upvotes,
        pv.Downvotes
    FROM 
        RecentPosts rp
    LEFT JOIN 
        PostVotes pv ON rp.PostId = pv.PostId
    ORDER BY 
        rp.Score DESC, (ISNULL(pv.Upvotes, 0) - ISNULL(pv.Downvotes, 0)) DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    ISNULL(tp.Upvotes, 0) AS Upvotes,
    ISNULL(tp.Downvotes, 0) AS Downvotes,
    ROUND((ISNULL(tp.Upvotes, 0) * 1.0 / NULLIF(ISNULL(tp.Upvotes, 0) + ISNULL(tp.Downvotes, 0), 0)) * 100, 2) AS UpvotePercentage
FROM 
    TopPosts tp
ORDER BY 
    UpvotePercentage DESC;
