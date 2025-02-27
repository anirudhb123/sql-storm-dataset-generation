
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        @rank := IF(@prevPostTypeId = p.PostTypeId, @rank + 1, 1) AS Rank,
        @prevPostTypeId := p.PostTypeId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    CROSS JOIN (SELECT @rank := 0, @prevPostTypeId := NULL) AS init
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate
),
TopPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CommentCount,
        rp.UpvoteCount,
        rp.DownvoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)
SELECT 
    tp.Title,
    tp.Score,
    tp.CommentCount,
    tp.UpvoteCount,
    tp.DownvoteCount,
    COALESCE(b.Name, 'No Badge') AS UserBadgeName,
    COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostsCount,
    COUNT(c.Id) AS TotalComments
FROM 
    TopPosts tp
LEFT JOIN 
    Posts p ON tp.PostId = p.Id
LEFT JOIN 
    Badges b ON p.OwnerUserId = b.UserId AND b.Date <= p.CreationDate
LEFT JOIN 
    PostLinks pl ON tp.PostId = pl.PostId
LEFT JOIN 
    Comments c ON tp.PostId = c.PostId
GROUP BY 
    tp.PostId, tp.Title, tp.Score, tp.CommentCount, tp.UpvoteCount, tp.DownvoteCount, b.Name
ORDER BY 
    tp.Score DESC, tp.CommentCount DESC;
