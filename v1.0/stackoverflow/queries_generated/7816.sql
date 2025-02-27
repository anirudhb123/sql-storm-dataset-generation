WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(uc.UpCount, 0) AS UpVotes,
        COALESCE(dc.DownCount, 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS UpCount 
        FROM 
            Votes 
        WHERE 
            VoteTypeId = 2 
        GROUP BY 
            PostId
    ) uc ON p.Id = uc.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS DownCount 
        FROM 
            Votes 
        WHERE 
            VoteTypeId = 3 
        GROUP BY 
            PostId
    ) dc ON p.Id = dc.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount, uc.UpCount, dc.DownCount
),
PostMetrics AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        UpVotes,
        DownVotes,
        CommentCount,
        Rank
    FROM RankedPosts
),
TopPosts AS (
    SELECT 
        pm.* 
    FROM 
        PostMetrics pm
    WHERE 
        Rank <= 10
)
SELECT 
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.CommentCount,
    t.TagName
FROM 
    TopPosts tp
JOIN 
    PostTags pt ON tp.PostId = pt.PostId
JOIN 
    Tags t ON pt.TagId = t.Id
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;
