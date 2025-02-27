WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.Score > (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1) -- Only for questions with above-average score
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS UpVotes, -- Upvotes counted
        SUM(COALESCE(v.VoteTypeId = 3, 0)) AS DownVotes  -- Downvotes counted
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
ActiveBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS Badges
    FROM 
        Badges b
    WHERE 
        b.Date > NOW() - INTERVAL '1 year'
    GROUP BY 
        b.UserId
)
SELECT 
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    ua.UpVotes,
    ua.DownVotes,
    COALESCE(ab.Badges, 'No badges') AS Badges,
    rp.Title,
    rp.Score,
    rp.ViewCount
FROM 
    UserActivity ua
LEFT JOIN 
    ActiveBadges ab ON ua.UserId = ab.UserId
JOIN 
    RankedPosts rp ON ua.TotalPosts > 10 -- Include only active users with more than 10 posts
WHERE 
    (ua.UpVotes - ua.DownVotes) > 5 -- Filter users with more upvotes than downvotes
ORDER BY 
    ua.UpVotes DESC, ua.TotalPosts DESC
LIMIT 50; -- Limit results for performance benchmarking
