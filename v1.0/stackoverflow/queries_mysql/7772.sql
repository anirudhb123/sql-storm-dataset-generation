
WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
HighReputationUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        TotalPosts,
        Questions,
        Answers
    FROM 
        UserPostCounts
    WHERE 
        TotalPosts > 50
        AND UserId IN (SELECT UserId FROM Badges WHERE Class = 1) 
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01 12:34:56', INTERVAL 1 YEAR)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT 
        ps.PostId, 
        ps.Title, 
        ps.CreationDate, 
        ps.ViewCount, 
        ps.Score, 
        ps.OwnerDisplayName,
        ps.CommentCount,
        @rank := IF(@prevOwnerDisplayName = ps.OwnerDisplayName, @rank + 1, 1) AS Rank,
        @prevOwnerDisplayName := ps.OwnerDisplayName
    FROM 
        PostStatistics ps
    CROSS JOIN (SELECT @rank := 0, @prevOwnerDisplayName := '') r
    JOIN 
        HighReputationUsers hru ON hru.DisplayName = ps.OwnerDisplayName
    ORDER BY 
        ps.OwnerDisplayName, ps.Score DESC
)
SELECT 
    t.OwnerDisplayName,
    t.Title,
    t.CreationDate,
    t.ViewCount,
    t.Score,
    t.CommentCount
FROM 
    TopPosts t
WHERE 
    t.Rank <= 3
ORDER BY 
    t.OwnerDisplayName, t.Score DESC;
