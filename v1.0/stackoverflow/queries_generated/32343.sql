WITH RECURSIVE PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions
    AND 
        p.Score > 10

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PopularPosts pp ON p.AcceptedAnswerId = pp.Id
    WHERE 
        p.PostTypeId = 2 -- Answers
)

, UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalBounties,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    pp.Title AS PopularPostTitle,
    pp.ViewCount AS PopularPostViews,
    pp.Score AS PopularPostScore,
    pp.CreationDate AS PopularPostDate,
    CASE 
        WHEN ua.TotalPosts > 0 THEN ROUND((ua.TotalUpVotes * 1.0 / NULLIF(ua.TotalPosts, 0)), 2)
        ELSE 0 
    END AS UpvoteRatio,
    CASE 
        WHEN ua.TotalPosts > 0 THEN ROUND((ua.TotalDownVotes * 1.0 / NULLIF(ua.TotalPosts, 0)), 2)
        ELSE 0 
    END AS DownvoteRatio
FROM 
    UserActivity ua
LEFT JOIN 
    PopularPosts pp ON ua.UserId = pp.OwnerUserId
ORDER BY 
    ua.TotalPosts DESC,    -- Primary sort by total posts
    pp.Score DESC          -- Secondary sort by popular post score
LIMIT 10;                 -- Limit to top 10 users
