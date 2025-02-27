
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(COUNT(DISTINCT c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(b.Name, 'None') AS BadgeName,
        u.Reputation,
        @row_number := @row_number + 1 AS RowNum
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Badges b ON u.Id = b.UserId,
        (SELECT @row_number := 0) AS rn
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.Reputation, b.Name
),
PostRanking AS (
    SELECT 
        PostId,
        Title,
        Score + UpVotes - DownVotes AS NetScore,
        CreationDate,
        CommentCount,
        Reputation,
        @rank := @rank + 1 AS Rank
    FROM 
        PostStats,
        (SELECT @rank := 0) AS r
    ORDER BY NetScore DESC
)
SELECT 
    PostId,
    Title,
    CreationDate,
    NetScore,
    CommentCount,
    Reputation,
    Rank
FROM 
    PostRanking
WHERE 
    Rank <= 10;
