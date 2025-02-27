WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Considering only questions (PostTypeId = 1)
    
    UNION ALL
    
    SELECT 
        p.Id AS PostId,
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
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(ve.VoteCount) AS AverageVotes,
        MAX(b.Name) AS HighestBadge,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT 
            PostId,
            COUNT(*) AS VoteCount
         FROM 
            Votes
         GROUP BY 
            PostId) ve ON p.Id = ve.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        DENSE_RANK() OVER (ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
)

SELECT 
    ph.PostId,
    ph.Title AS QuestionTitle,
    COALESCE(rp.CommentCount, 0) AS TotalComments,
    ua.UserId,
    ua.Reputation,
    ua.PostCount,
    ua.AverageVotes,
    ua.HighestBadge,
    ua.TotalBadgeClass,
    ph.Level
FROM 
    PostHierarchy ph
JOIN 
    UserActivity ua ON ph.PostId IN (SELECT h.PostId FROM PostHierarchy h WHERE h.Level = 1) -- joining top-level questions only
LEFT JOIN 
    RecentPosts rp ON rp.Id = ph.PostId
WHERE 
    ua.Reputation > 100
    AND (SELECT COUNT(*) FROM Votes v WHERE v.PostId = ph.PostId AND v.VoteTypeId = 2) > 5 -- questions with more than 5 upvotes
ORDER BY 
    TotalComments DESC, ua.Reputation DESC
LIMIT 100;
