-- Performance Benchmarking Query
WITH TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,      -- UpMod
        SUM(v.VoteTypeId = 3) AS DownVotes     -- DownMod
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  -- Filtering only Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS PostsCreated,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    tu.UserId,
    tu.DisplayName AS UserDisplayName,
    tu.PostsCreated,
    tu.AvgReputation
FROM 
    TopPosts tp
JOIN 
    TopUsers tu ON tp.Score > 50  -- Example condition to join with a threshold on posts' score
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC
LIMIT 100;  -- For performance testing, limit the results
