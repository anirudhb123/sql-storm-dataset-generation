WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - 
                 SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - 
                 SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) DESC) AS PostRank
    FROM 
        Posts p 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
),
HighScoreUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
)
SELECT 
    u.DisplayName,
    COUNT(p.Id) AS TotalPosts,
    AVG(rp.Score) AS AverageScore
FROM 
    HighScoreUsers u
LEFT JOIN 
    RankedPosts rp ON u.UserId = rp.OwnerUserId
LEFT JOIN 
    Posts p ON p.OwnerUserId = u.UserId
GROUP BY 
    u.DisplayName
HAVING 
    AVG(rp.Score) > 10
ORDER BY 
    AverageScore DESC;

-- Fetching comments on high scoring posts
SELECT 
    c.Text,
    c.CreationDate,
    p.Title,
    u.DisplayName AS Commenter
FROM 
    Comments c
JOIN 
    Posts p ON c.PostId = p.Id
JOIN 
    Users u ON c.UserId = u.Id
WHERE 
    p.Id IN (SELECT DISTINCT p.Id 
              FROM Posts p 
              JOIN Votes v ON p.Id = v.PostId 
              GROUP BY p.Id 
              HAVING SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - 
                     SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) > 5)
ORDER BY 
    c.CreationDate DESC;

-- Finding moderated actions along with details for specific posts
SELECT 
    ph.UserDisplayName,
    ph.Comment,
    ph.CreationDate,
    pt.Name AS PostType,
    p.Title,
    CASE 
        WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closed/Reopened'
        ELSE 'Other' 
    END AS ActionType
FROM 
    PostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
JOIN 
    PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
WHERE 
    ph.CreationDate >= NOW() - INTERVAL '1 year'
    AND (ph.PostHistoryTypeId = 10 OR ph.PostHistoryTypeId = 11)
ORDER BY 
    ph.CreationDate DESC;
