WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostsCreated,
        SUM(COALESCE(v.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(v.DownVotes, 0)) AS TotalDownVotes,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId) v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) -- Considering only Questions and Answers
    ORDER BY 
        p.Score DESC
),
RecentActivity AS (
    SELECT 
        ph.PostId,
        ph.Title,
        ph.Level,
        ph.ParentId,
        ph.CreationDate,
        u.DisplayName AS UserDisplayName
    FROM 
        PostHistory ph
    LEFT JOIN 
        Users u ON ph.UserId = u.Id
    WHERE 
        ph.CreationDate > NOW() - INTERVAL '30 days'
)

SELECT 
    ua.DisplayName AS UserName,
    ua.PostsCreated,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    pp.Title AS PopularPostTitle,
    pp.CreationDate AS PopularPostDate,
    pp.Score AS PopularPostScore,
    COALESCE(r.UserDisplayName, 'N/A') AS RecentEditor,
    COUNT(DISTINCT ph.PostId) AS TotalEditedPosts
FROM 
    UserActivity ua
LEFT JOIN 
    PopularPosts pp ON ua.UserId = pp.OwnerUserId
LEFT JOIN 
    RecentActivity r ON pp.Id = r.PostId
LEFT JOIN 
    PostHierarchy ph ON pp.Id = ph.PostId
WHERE 
    ua.PostsCreated > 10 -- Filter users with more than 10 posts
GROUP BY 
    ua.UserId, pp.Title, pp.CreationDate, pp.Score, r.UserDisplayName
ORDER BY 
    ua.TotalUpVotes DESC, ua.TotalDownVotes ASC;
