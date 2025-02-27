WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' AND p.Score > 0
),
PostMetrics AS (
    SELECT 
        r.PostTypeId,
        COUNT(*) AS TotalPosts,
        AVG(r.OwnerReputation) AS AvgOwnerReputation,
        SUM(r.Score) AS TotalScore,
        SUM(r.ViewCount) AS TotalViewCount
    FROM 
        RankedPosts r
    JOIN 
        PostTypes pt ON r.PostTypeId = pt.Id
    GROUP BY 
        r.PostTypeId
),
MostActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(v.VoteTypeId = 2) AS UpVotesReceived
    FROM 
        Users u 
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        PostsCount DESC
    LIMIT 10
)
SELECT 
    pt.Name AS PostType,
    pm.TotalPosts,
    pm.AvgOwnerReputation,
    pm.TotalScore,
    pm.TotalViewCount,
    au.DisplayName AS ActiveUser,
    au.PostsCount,
    au.UpVotesReceived
FROM 
    PostMetrics pm
JOIN 
    PostTypes pt ON pm.PostTypeId = pt.Id
JOIN 
    MostActiveUsers au ON au.PostsCount > 0
ORDER BY 
    pm.TotalPosts DESC, pm.TotalScore DESC;
