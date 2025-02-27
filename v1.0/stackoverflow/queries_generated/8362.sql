WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND p.Score > 10 
), TopPostStats AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.Score,
        r.UpVotes,
        r.DownVotes,
        r.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (ORDER BY r.Score DESC) AS ScoreRank
    FROM 
        RankedPosts r
    JOIN 
        Users u ON r.PostId = u.Id
    WHERE 
        r.PostRank = 1
)
SELECT 
    tps.PostId,
    tps.Title,
    tps.CreationDate,
    tps.Score,
    tps.UpVotes,
    tps.DownVotes,
    tps.CommentCount,
    tps.OwnerDisplayName,
    CASE 
        WHEN tps.ScoreRank <= 10 THEN 'Top'
        ELSE 'Other'
    END AS RankCategory
FROM 
    TopPostStats tps
ORDER BY 
    tps.ScoreRank, tps.CreationDate DESC;
