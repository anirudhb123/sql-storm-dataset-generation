WITH RecursiveUserHierarchy AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        CreationDate,
        LastAccessDate,
        0 AS Level
    FROM 
        Users
    WHERE 
        Id IN (SELECT DISTINCT UserId FROM Badges)
    
    UNION ALL
    
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        uh.Level + 1
    FROM 
        Users u
    INNER JOIN 
        RecursiveUserHierarchy uh ON u.Id = uh.Id -- This join condition can be replaced based on the hierarchy logic
    WHERE 
        u.Reputation > uh.Reputation
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        COALESCE(COUNT(com.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments com ON p.Id = com.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Considering only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId, p.AcceptedAnswerId
),
TopPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.ViewCount,
        pd.Score,
        pd.CommentCount,
        ROW_NUMBER() OVER (ORDER BY pd.Score DESC) AS Rank
    FROM 
        PostDetails pd
)

SELECT 
    u.DisplayName,
    u.Reputation,
    up.PostId,
    up.Title,
    up.ViewCount,
    up.Score,
    up.CommentCount
FROM 
    RecursiveUserHierarchy u
JOIN 
    TopPosts up ON u.Id = up.PostId
WHERE 
    up.Rank <= 10 -- Top 10 posts by Score
ORDER BY 
    u.Reputation DESC, up.Score DESC;

-- Incorporate an outer join to fetch users without badges
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    b.Name AS BadgeName
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    b.Name IS NULL AND 
    (u.Reputation < 1000 OR u.Reputation IS NULL)
ORDER BY 
    u.CreationDate DESC;

-- Calculate the average score of accepted answers by post
WITH AcceptedAnswers AS (
    SELECT 
        p.OwnerUserId,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    WHERE 
        p.Id IN (SELECT AcceptedAnswerId FROM Posts WHERE AcceptedAnswerId IS NOT NULL)
    GROUP BY 
        p.OwnerUserId
)

SELECT 
    u.DisplayName,
    COALESCE(aa.AvgScore, 0) AS AverageAcceptedScore
FROM 
    Users u
LEFT JOIN 
    AcceptedAnswers aa ON u.Id = aa.OwnerUserId
ORDER BY 
    AverageAcceptedScore DESC;

-- Final result combining all relevant metrics via FULL OUTER JOIN
SELECT 
    u.DisplayName,
    COALESCE(badge.BadgeCount, 0) AS BadgeCount,
    COALESCE(top.PostCount, 0) AS TopPostsCount,
    COALESCE(avgAnswers.AverageAcceptedScore, 0) AS AverageAcceptedScore
FROM 
    Users u
FULL OUTER JOIN 
    (SELECT 
         OwnerUserId,
         COUNT(*) AS PostCount 
     FROM 
         Posts 
     GROUP BY 
         OwnerUserId) top ON u.Id = top.OwnerUserId
FULL OUTER JOIN 
    (SELECT 
         OwnerUserId,
         COUNT(*) AS BadgeCount 
     FROM 
         Badges 
     GROUP BY 
         OwnerUserId) badge ON u.Id = badge.OwnerUserId
FULL OUTER JOIN 
    (SELECT 
         p.OwnerUserId,
         AVG(p.Score) AS AverageAcceptedScore
     FROM 
         Posts p 
     WHERE 
         p.Id IN (SELECT AcceptedAnswerId FROM Posts WHERE AcceptedAnswerId IS NOT NULL) 
     GROUP BY 
         p.OwnerUserId) avgAnswers ON u.Id = avgAnswers.OwnerUserId
ORDER BY 
    u.DisplayName;
