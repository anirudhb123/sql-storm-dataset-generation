WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS UserPostRank,
        MAX(v.CreationDate) AS LastVoteDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) -- Upvotes and Downvotes only
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
FilteredUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COALESCE(b.Name, 'No Badge') AS BadgeName
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId AND b.Class = 1 -- Gold badges only
    WHERE 
        u.Reputation > 1000
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        MAX(ph.UserId) AS LastEditorId,
        COUNT(DISTINCT ph.Id) AS EditCount
    FROM 
        Posts p
    INNER JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (4, 5) -- Edit Title and Body
    GROUP BY 
        p.Id
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    SUM(rp.ViewCount) AS TotalViews,
    SUM(rp.Score) AS TotalScore,
    AVG(rp.CommentCount) AS AvgCommentsPerPost,
    MAX(ra.LastEditDate) AS MostRecentEditDate,
    ra.EditCount AS TotalEdits,
    u.BadgeName
FROM 
    FilteredUsers u
JOIN 
    RankedPosts rp ON u.UserId = rp.PostId -- Correlated Subquery
LEFT JOIN 
    RecentActivity ra ON rp.PostId = ra.PostId
WHERE 
    rp.UserPostRank <= 5 -- Get top 5 recent posts per user
GROUP BY 
    u.UserId, u.DisplayName, u.Reputation, u.BadgeName
HAVING 
    COUNT(DISTINCT rp.PostId) > 3 -- Users with more than 3 posts
ORDER BY 
    TotalViews DESC
LIMIT 10; -- Limit to top 10 users by views
