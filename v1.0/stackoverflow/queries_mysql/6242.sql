
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate > (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR)
), 
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 3
), 
PostStats AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.ViewCount,
        tp.Score,
        tp.OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes, 
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes  
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.CreationDate, tp.ViewCount, tp.Score, tp.OwnerDisplayName
)
SELECT 
    tp.*,
    (tp.ViewCount + ps.UpVotes - ps.DownVotes) AS EngagementScore 
FROM 
    PostStats ps
JOIN 
    TopPosts tp ON ps.PostId = tp.PostId
ORDER BY 
    EngagementScore DESC
LIMIT 10;
