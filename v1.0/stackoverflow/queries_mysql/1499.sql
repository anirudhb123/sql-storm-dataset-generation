
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 3 MONTH)
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.ViewCount,
        ps.UpVotes,
        ps.DownVotes,
        ps.CommentCount,
        COALESCE(phs.CloseReopenCount, 0) AS CloseReopenCount,
        COALESCE(phs.DeleteCount, 0) AS DeleteCount,
        @rank := @rank + 1 AS Rank
    FROM 
        PostStats ps
    LEFT JOIN 
        PostHistoryStats phs ON ps.PostId = phs.PostId,
        (SELECT @rank := 0) r
    ORDER BY 
        ps.Score DESC
)
SELECT 
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.CommentCount,
    tp.CloseReopenCount,
    tp.DeleteCount
FROM 
    TopPosts tp
WHERE 
    tp.Rank <= 10
ORDER BY 
    tp.Score DESC;
