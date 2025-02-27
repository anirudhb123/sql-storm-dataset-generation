WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.OwnerUserId,
        p.PostTypeId,
        p.Title,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.OwnerUserId, p.PostTypeId, p.Title, p.CreationDate
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        CASE 
            WHEN r.OwnerPostRank IS NOT NULL THEN r.OwnerPostRank 
            ELSE 0 
        END AS PostsCreated,
        COALESCE(SUM(b.Class), 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts r ON u.Id = r.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, r.OwnerPostRank
)
SELECT 
    u.UserId,
    u.Reputation,
    u.PostsCreated,
    u.BadgeCount,
    CASE 
        WHEN u.Reputation = 0 THEN 'No Reputation'
        WHEN u.Reputation BETWEEN 1 AND 500 THEN 'Novice'
        WHEN u.Reputation BETWEEN 501 AND 1000 THEN 'Intermediate'
        ELSE 'Expert' 
    END AS UserLevel,
    STRING_AGG(DISTINCT CONCAT('<', p.Title, '> with ', COALESCE(c.CommentCount, 0), ' comments'), ', ') AS RecentPosts
FROM 
    UserReputation u
LEFT JOIN 
    RankedPosts p ON u.UserId = p.OwnerUserId AND p.OwnerPostRank < 5
LEFT JOIN 
    (SELECT p.OwnerUserId, COUNT(c.Id) AS CommentCount 
     FROM Posts p 
     LEFT JOIN Comments c ON p.Id = c.PostId 
     WHERE p.PostTypeId = 1 
     GROUP BY p.OwnerUserId) c ON u.UserId = c.OwnerUserId
GROUP BY 
    u.UserId, u.Reputation, u.PostsCreated, u.BadgeCount
HAVING 
    u.Reputation IS NOT NULL AND 
    (u.BadgeCount > 0 OR u.PostsCreated > 0)
ORDER BY 
    u.Reputation DESC, u.BadgeCount DESC;

WITH RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END AS IsQuestion,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes,
        SUM(v.VoteTypeId = 3) AS TotalDownVotes,
        p.CreationDate,
        DENSE_RANK() OVER(PARTITION BY OwnerUserId ORDER BY COUNT(c.Id) DESC) AS ActivityRank
    FROM 
        Posts p
    JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.OwnerUserId, p.PostTypeId, p.CreationDate
)
SELECT 
    p.Title,
    p.OwnerDisplayName,
    p.CreationDate,
    COALESCE(r.TotalUpVotes, 0) - COALESCE(r.TotalDownVotes, 0) AS NetVotes,
    CASE 
        WHEN (r.IsQuestion = 1 AND r.TotalUpVotes > 5) THEN 'Hot Q'
        ELSE 'Regular Post'
    END AS PopularityFlag,
    RANK() OVER(ORDER BY COALESCE(r.TotalUpVotes, 0) DESC) AS GlobalRanking
FROM 
    RecentActivity r
JOIN 
    Posts p ON r.PostId = p.Id
WHERE 
    (r.IsQuestion = 1 AND r.TotalUpVotes > 10) OR 
    (r.TotalDownVotes IS NULL)
ORDER BY 
    GlobalRanking;
