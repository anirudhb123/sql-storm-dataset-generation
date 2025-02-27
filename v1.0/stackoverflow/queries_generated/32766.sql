WITH RecursivePostCTE AS (
    -- Recursive common table expression to get the hierarchy of posts and their answers
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        0 AS Level,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with Questions

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        Level + 1,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount
    FROM 
        Posts p
    INNER JOIN RecursivePostCTE r ON p.ParentId = r.PostId
    WHERE 
        p.PostTypeId = 2  -- Include Answers
),

AggregateData AS (
    -- Aggregate data for each user related to posts and votes
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),

PostStatistics AS (
    -- Calculating statistics for posts
    SELECT 
        rp.PostId,
        rp.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        AVG(p.Score) OVER(PARTITION BY rp.OwnerUserId) AS AvgScore,
        RANK() OVER (PARTITION BY rp.OwnerUserId ORDER BY rp.CreationDate DESC) AS RecentRank
    FROM 
        RecursivePostCTE rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    GROUP BY 
        rp.PostId, rp.OwnerUserId, rp.CreationDate
)

-- Final query combining all components with filtering
SELECT 
    a.DisplayName,
    a.TotalPosts,
    a.TotalQuestions,
    a.TotalAnswers,
    a.TotalBounty,
    a.TotalScore,
    p.PostId,
    p.CommentCount,
    p.AvgScore,
    p.RecentRank,
    CASE 
        WHEN p.CommentCount > 10 THEN 'Highly Active'
        WHEN p.CommentCount IS NULL THEN 'No Comments'
        ELSE 'Moderately Active'
    END AS ActivityLevel
FROM 
    AggregateData a
JOIN 
    PostStatistics p ON a.UserId = p.OwnerUserId
WHERE 
    a.TotalPosts > 5  -- Filter condition for users with more than 5 posts
ORDER BY 
    a.TotalScore DESC, 
    p.RecentRank
FETCH FIRST 100 ROWS ONLY;  -- Limit the results to top 100

