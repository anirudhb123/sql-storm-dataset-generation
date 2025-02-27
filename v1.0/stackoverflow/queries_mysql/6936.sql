
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(pt.Name, 'Unknown') AS PostType,
        COALESCE(u.DisplayName, 'Deleted User') AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.UserId END) AS UpVotes,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.UserId END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, pt.Name, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        ViewCount, 
        PostType, 
        OwnerDisplayName, 
        CommentCount, 
        UpVotes, 
        DownVotes,
        @rank := @rank + 1 AS Rank
    FROM 
        PostStats, (SELECT @rank := 0) r
    ORDER BY 
        Score DESC, ViewCount DESC
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.PostType,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    CASE 
        WHEN tp.Rank <= 10 THEN 'Top Ranked'
        WHEN tp.Rank BETWEEN 11 AND 20 THEN 'Next Best'
        ELSE 'Below 20'
    END AS RankCategory
FROM 
    TopPosts tp
WHERE 
    tp.CommentCount > 0
ORDER BY 
    tp.Rank;
