WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2022-01-01' 
        AND p.Score >= 0
    GROUP BY 
        p.Id, U.DisplayName, p.PostTypeId, p.Title, p.Score, p.CreationDate, p.ViewCount
),

TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        CreationDate,
        OwnerDisplayName,
        CommentCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)

SELECT 
    tp.Title,
    tp.Score,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.CommentCount,
    COALESCE(tp.UpVotes, 0) AS TotalUpVotes,
    COALESCE(tp.DownVotes, 0) AS TotalDownVotes,
    CASE 
        WHEN tp.UpVotes IS NULL THEN 'No Votes'
        WHEN tp.UpVotes > tp.DownVotes THEN 'Trending Up'
        ELSE 'Trending Down'
    END AS TrendDirection,
    (SELECT COUNT(*) FROM Posts WHERE ViewCount > 1000) AS HighTrafficPosts
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC;

-- Recursive CTE to find highest scores in different post types
WITH RECURSIVE HighScores AS (
    SELECT 
        PostTypeId,
        MAX(Score) AS MaxScore
    FROM 
        Posts
    GROUP BY 
        PostTypeId
    UNION ALL
    SELECT 
        ps.PostTypeId,
        MAX(ps.Score)
    FROM 
        Posts ps
    INNER JOIN 
        HighScores hs ON ps.Score < hs.MaxScore
    GROUP BY 
        ps.PostTypeId
)
SELECT 
    p.Id,
    p.Title,
    p.Score,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount
FROM 
    Posts p
JOIN 
    HighScores hs ON p.PostTypeId = hs.PostTypeId
WHERE 
    p.Score = hs.MaxScore
ORDER BY 
    UpVoteCount DESC;
