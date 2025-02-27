WITH RecursiveUserStats AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        UpVotes,
        DownVotes,
        0 AS Level
    FROM 
        Users
    WHERE 
        Reputation > 1000
    
    UNION ALL
    
    SELECT 
        u.Id,
        u.Reputation,
        u.CreationDate,
        u.UpVotes,
        u.DownVotes,
        us.Level + 1
    FROM 
        Users u
    INNER JOIN 
        RecursiveUserStats us ON u.Reputation > us.Reputation
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(badgeCount.Count, 0) AS BadgeCount,
    COALESCE(postStats.PostCount, 0) AS TotalPosts,
    COALESCE(AVG(v.Score), 0) AS AvgScore,
    CASE 
        WHEN COALESCE(AVG(v.Score), 0) > 0 THEN 'Active Contributor'
        ELSE 'Less Active'
    END AS ActivityLevel,
    ROW_NUMBER() OVER (ORDER BY COALESCE(badgeCount.Count, 0) DESC) AS Rank
FROM 
    Users u
LEFT JOIN 
    (SELECT 
         UserId,
         COUNT(*) AS Count
     FROM 
         Badges
     GROUP BY 
         UserId) badgeCount ON u.Id = badgeCount.UserId
LEFT JOIN 
    (SELECT 
         OwnerUserId,
         COUNT(*) AS PostCount
     FROM 
         Posts
     WHERE 
         CreationDate > CURRENT_DATE - INTERVAL '1 year'
     GROUP BY 
         OwnerUserId) postStats ON u.Id = postStats.OwnerUserId
LEFT JOIN 
    Votes v ON u.Id = v.UserId
WHERE 
    u.Reputation >= 1000 
    AND (v.CreationDate >= CURRENT_DATE - INTERVAL '1 month' OR v.UserId IS NULL)
GROUP BY 
    u.Id, u.DisplayName, badgeCount.Count, postStats.PostCount
HAVING 
    COUNT(DISTINCT v.PostId) > 5 
ORDER BY 
    Rank;

-- Evaluating posts with the highest interaction based on user activity and badge status
WITH Interactions AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 month'
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    i.PostId,
    i.Title,
    i.CommentCount,
    i.UpVotes,
    i.DownVotes,
    CASE 
        WHEN i.UpVotes - i.DownVotes > 10 THEN 'Hot Post'
        WHEN i.CommentCount > 5 THEN 'Engaging Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    Interactions i
WHERE 
    i.CommentCount > 0 
ORDER BY 
    i.UpVotes DESC, i.CommentCount DESC
LIMIT 10;

-- Analyzing post editing histories, especially closed posts
SELECT 
    p.Title,
    ph.PostId,
    ph.UserDisplayName,
    ph.CreationDate,
    ph.Comment,
    ph.Text AS EditedContent,
    ph.PostHistoryTypeId,
    SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseReopenCount
FROM 
    PostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
WHERE 
    ph.CreationDate BETWEEN CURRENT_DATE - INTERVAL '1 year' AND CURRENT_DATE
GROUP BY 
    p.Title, ph.PostId, ph.UserDisplayName, ph.CreationDate, ph.Comment, ph.Text, ph.PostHistoryTypeId
HAVING 
    COUNT(ph.Id) > 1
ORDER BY 
    CloseReopenCount DESC;

