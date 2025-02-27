WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
),
TopPosts AS (
    SELECT 
        rp.*,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    WHERE 
        rp.Rank <= 10
    GROUP BY 
        rp.PostId, rp.Title, rp.Score, rp.ViewCount, rp.AnswerCount, rp.CreationDate
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.CommentCount,
    tp.UpvoteCount,
    tp.DownvoteCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation,
    pt.Name AS PostTypeName,
    (SELECT STRING_AGG(t.TagName, ', ') 
     FROM Tags t 
     WHERE t.Id IN (SELECT UNNEST(string_to_array(tp.Tags, '<>')::int[]))) AS Tags
FROM 
    TopPosts tp
JOIN 
    Users u ON u.Id = tp.OwnerUserId
JOIN 
    PostTypes pt ON pt.Id = tp.PostTypeId
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
