-- Performance Benchmarking Query
WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        pt.Name AS PostType,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount,
        AVG(p.Score) AS AverageScore,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- BountyStart and BountyClose
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts from the last 1 year
    GROUP BY 
        p.Id, pt.Name
),
PostTypeSummary AS (
    SELECT 
        PostType,
        COUNT(PostId) AS TotalPosts,
        SUM(CommentCount) AS TotalComments,
        SUM(TotalBountyAmount) AS TotalBounty,
        AVG(AverageScore) AS AvgScore,
        SUM(BadgeCount) AS TotalBadges
    FROM 
        PostStatistics
    GROUP BY 
        PostType
)

SELECT 
    PostType,
    TotalPosts,
    TotalComments,
    TotalBounty,
    AvgScore,
    TotalBadges
FROM 
    PostTypeSummary
ORDER BY 
    TotalPosts DESC;
