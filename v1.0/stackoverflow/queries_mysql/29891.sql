
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        pt.Name AS PostType,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount, 
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount 
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
        p.CreationDate >= '2022-01-01' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, pt.Name, u.DisplayName
), 
PostStatistics AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        PostType,
        OwnerDisplayName,
        CommentCount,
        UpVoteCount,
        DownVoteCount,
        @rank := @rank + 1 AS Rank
    FROM 
        RankedPosts, (SELECT @rank := 0) r
    ORDER BY 
        UpVoteCount DESC, CommentCount DESC
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.PostType,
    ps.OwnerDisplayName,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    ps.Rank,
    ROUND((CAST(ps.UpVoteCount AS DECIMAL(10,2)) / NULLIF((ps.UpVoteCount + ps.DownVoteCount), 0)) * 100, 2) AS UpVotePercentage 
FROM 
    PostStatistics ps
WHERE 
    ps.Rank <= 10 
ORDER BY 
    ps.Rank;
