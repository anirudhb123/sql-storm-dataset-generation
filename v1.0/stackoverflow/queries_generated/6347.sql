WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COALESCE(SUM(v.VoteTypeId), 0) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        CommentCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    t.PostId,
    t.Title,
    t.CreationDate,
    t.ViewCount,
    t.CommentCount,
    t.UpVotes,
    t.DownVotes,
    CASE 
        WHEN t.UpVotes + t.DownVotes > 0 THEN ROUND((t.UpVotes::decimal / (t.UpVotes + t.DownVotes)) * 100, 2)
        ELSE 0 
    END AS UpvotePercentage
FROM 
    TopPosts t
ORDER BY 
    t.UpVotes DESC, t.ViewCount DESC;
