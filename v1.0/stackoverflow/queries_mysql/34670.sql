
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId, 
        p.ParentId, 
        p.Title, 
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL 

    UNION ALL

    SELECT 
        p.Id AS PostId, 
        p.ParentId, 
        p.Title, 
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(p.Id) AS PostCount, 
        SUM(co.Score) AS CommentScore, 
        SUM(CASE WHEN co.CreationDate >= (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL 30 DAY) THEN 1 ELSE 0 END) AS RecentComments,
        RANK() OVER (PARTITION BY u.Id ORDER BY COUNT(V.Id) DESC) AS VoteRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments co ON p.Id = co.PostId
    LEFT JOIN 
        Votes V ON p.Id = V.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostsWithTags AS (
    SELECT 
        p.Id AS PostId,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags,
        p.Title,
        p.Score
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) AS tag
         FROM 
         (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag ON true 
    LEFT JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        p.Id, p.Title, p.Score
)
SELECT 
    ua.DisplayName,
    ua.PostCount,
    ua.CommentScore,
    ua.RecentComments,
    ph.Title AS PostTitle,
    pt.Tags,
    SUM(CASE 
            WHEN v.VoteTypeId IN (2, 3) THEN 1 
            ELSE 0 
        END) AS TotalVotes,
    COUNT(DISTINCT co.Id) AS TotalComments
FROM 
    UserActivity ua
JOIN 
    PostsWithTags pt ON ua.UserId = pt.PostId
JOIN 
    PostHierarchy ph ON ph.PostId = pt.PostId
LEFT JOIN 
    Votes v ON v.PostId = pt.PostId
LEFT JOIN 
    Comments co ON co.PostId = pt.PostId
WHERE 
    ua.VoteRank = 1 
    AND ph.Level < 2
GROUP BY 
    ua.DisplayName, ua.PostCount, ua.CommentScore, ua.RecentComments, ph.Title, pt.Tags
ORDER BY 
    ua.PostCount DESC, TotalVotes DESC 
LIMIT 50;
