WITH RecursiveUserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation >= 1000 -- Filter to more reputable users
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate, u.LastAccessDate, u.Views, u.UpVotes, u.DownVotes
),

RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days' -- Only consider posts from the last 30 days
),

PostScoreAnalysis AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty,
        MAX(p.LastActivityDate) AS LastActivity,
        CASE 
            WHEN COUNT(c.Id) > 0 THEN 'Has Comments'
            ELSE 'No Comments'
        END AS CommentStatus
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.Score
)

SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    u.Views,
    u.UpVotes,
    u.DownVotes,
    u.PostCount,
    u.PositivePosts,
    rp.PostId,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    rp.ViewCount AS RecentPostViews,
    psa.Score AS PostScore,
    psa.CommentCount,
    psa.TotalBounty,
    psa.CommentStatus
FROM 
    RecursiveUserActivity u
LEFT JOIN 
    RecentPosts rp ON u.UserId = rp.OwnerDisplayName
LEFT JOIN 
    PostScoreAnalysis psa ON rp.PostId = psa.PostId 
WHERE 
    u.PostRank = 1  -- Focus on the latest post for each user
ORDER BY 
    u.Reputation DESC, 
    rp.CreationDate DESC
LIMIT 50; -- Limit the results for performance benchmarking
