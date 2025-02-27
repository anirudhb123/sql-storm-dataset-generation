
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS CloseCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 90 DAY)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
PostStats AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        OwnerDisplayName,
        CommentCount,
        UpVotes,
        DownVotes,
        CloseCount,
        (Score + UpVotes - DownVotes) AS NetScore
    FROM 
        RecentPosts
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.OwnerDisplayName,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.CloseCount,
    ps.NetScore,
    @rank := @rank + 1 AS Rank
FROM 
    PostStats ps, (SELECT @rank := 0) r
WHERE 
    ps.CloseCount = 0
ORDER BY 
    ps.NetScore DESC
LIMIT 10;
