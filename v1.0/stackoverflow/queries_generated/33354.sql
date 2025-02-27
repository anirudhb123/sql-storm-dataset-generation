WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        0 AS Depth
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Start with questions
    
    UNION ALL
    
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        cte.Depth + 1
    FROM 
        Posts p
    JOIN 
        RecursivePostCTE cte ON p.ParentId = cte.PostId -- Join back to children
    WHERE 
        p.PostTypeId = 2 -- Only include answers
),
PostVoteSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownvoteCount,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS Badges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    DISTINCT p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    COALESCE(v.UpvoteCount, 0) AS Upvotes,
    COALESCE(v.DownvoteCount, 0) AS Downvotes,
    COALESCE(u_bad.BadgeCount, 0) AS badge_count,
    u_bad.Badges,
    CASE 
        WHEN p.LastActivityDate IS NOT NULL AND p.CreationDate < NOW() - INTERVAL '30 days' THEN 'Inactive'
        ELSE 'Active'
    END AS PostStatus,
    cte.Depth
FROM 
    RecursivePostCTE cte
JOIN 
    Posts p ON p.Id = cte.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostVoteSummary v ON p.Id = v.PostId
LEFT JOIN 
    UserBadges u_bad ON u.Id = u_bad.UserId
ORDER BY 
    cte.Depth, p.CreationDate DESC;
