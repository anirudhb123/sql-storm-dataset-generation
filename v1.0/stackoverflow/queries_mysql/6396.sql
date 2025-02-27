
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        u.DisplayName AS OwnerName,
        @row_num := IF(@prev_post_type_id = p.PostTypeId, @row_num + 1, 1) AS Rank,
        @prev_post_type_id := p.PostTypeId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    CROSS JOIN 
        (SELECT @row_num := 0, @prev_post_type_id := NULL) AS vars
    WHERE 
        p.CreationDate >= '2023-10-01 12:34:56'
    ORDER BY 
        p.PostTypeId, p.Score DESC
),
TopPosts AS (
    SELECT 
        PostId, Title, Score, ViewCount, OwnerName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
PostStats AS (
    SELECT 
        tp.PostId, 
        tp.Title, 
        tp.Score, 
        tp.ViewCount, 
        tp.OwnerName, 
        COUNT(c.Id) AS CommentCount, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.Score, tp.ViewCount, tp.OwnerName
)
SELECT 
    ps.PostId, 
    ps.Title, 
    ps.Score, 
    ps.ViewCount, 
    ps.OwnerName, 
    ps.CommentCount, 
    ps.UpVotes, 
    ps.DownVotes,
    (ps.UpVotes - ps.DownVotes) AS NetVotes
FROM 
    PostStats ps
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;
