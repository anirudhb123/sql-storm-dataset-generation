WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        Users
), 
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS NetVotes,
        COUNT(c.Id) FILTER (WHERE c.UserId IS NOT NULL) AS CommentCount,
        COUNT(DISTINCT l.RelatedPostId) AS RelatedPostsCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id 
    LEFT JOIN 
        PostLinks l ON l.PostId = p.Id 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.OwnerUserId
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.ViewCount > 1000 THEN 1 ELSE 0 END) AS HighViewCountPosts
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        ph.PostId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    p.PostId,
    pm.NetVotes,
    pm.CommentCount,
    ph.EditCount,
    ts.TagName,
    ts.TotalPosts,
    ts.HighViewCountPosts,
    CASE 
        WHEN u.Reputation >= 1000 THEN 'Experienced'
        WHEN u.Reputation BETWEEN 500 AND 999 THEN 'Intermediate'
        ELSE 'Novice'
    END AS UserLevel
FROM 
    UserReputation u
LEFT JOIN 
    PostMetrics pm ON pm.OwnerUserId = u.UserId
LEFT JOIN 
    PostHistoryStats ph ON ph.PostId = pm.PostId
LEFT JOIN 
    Tags t ON t.Count > 100
LEFT JOIN 
    TagStatistics ts ON ts.TagName = t.TagName
WHERE 
    u.Reputation IS NOT NULL
ORDER BY 
    u.Reputation DESC, pm.NetVotes DESC, pm.CommentCount DESC
LIMIT 
    100;

-- Dynamic checks for NULL logic
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM Users WHERE Reputation IS NULL) THEN 'Some users have no reputation'
        ELSE 'All users have reputation'
    END AS ReputationCheck,
    COALESCE((SELECT MAX(Reputation) FROM Users), 'No reputation data available') AS MaxReputation,
    (SELECT COUNT(*) FROM Posts WHERE AcceptedAnswerId IS NOT NULL) AS QuestionsWithAcceptedAnswers;
