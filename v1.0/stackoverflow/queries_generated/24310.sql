WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
),

PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.ViewCount,
        rp.Score,
        rp.UpVoteCount,
        rp.DownVoteCount,
        CASE 
            WHEN rp.Rank = 1 AND rp.ViewCount > 100 THEN 'Top View'
            WHEN rp.Score > 10 AND rp.UpVoteCount > 5 THEN 'Popular'
            ELSE 'Regular'
        END AS PostCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),

VoteSummary AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)

SELECT 
    ps.*,
    vs.TotalVotes,
    vs.UpVotes AS TotalUpVotes,
    vs.DownVotes AS TotalDownVotes,
    CASE 
        WHEN vs.TotalVotes IS NULL THEN 'No Votes Yet'
        ELSE CONCAT('Votes: ', vs.TotalVotes)
    END AS VoteDescription
FROM 
    PostStats ps
LEFT JOIN 
    VoteSummary vs ON ps.PostId = vs.PostId
WHERE 
    ps.OwnerDisplayName IS NOT NULL -- Filtering out community posts
ORDER BY 
    ps.PostCategory, ps.ViewCount DESC;

-- Further complexity: getting badges of users who posted the top posts
SELECT 
    ps.PostId,
    ps.Title,
    b.Name AS BadgeName
FROM 
    PostStats ps
LEFT JOIN 
    Badges b ON ps.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = b.UserId)
WHERE 
    ps.PostCategory = 'Top View'
    AND (SELECT COUNT(*) FROM Badges WHERE UserId = (SELECT Id FROM Users WHERE DisplayName = ps.OwnerDisplayName)) > 0
ORDER BY 
    ps.PostId;

This SQL query involves complex operations with Common Table Expressions (CTEs) to rank and categorize posts, aggregate voting statistics with window functions, and utilize filtering with correlated subqueries. It showcases advanced patterns including outer joins and predicates, combining various constructs to form a comprehensive performance benchmarking query for analyzing posts in a Stack Overflow schema.
