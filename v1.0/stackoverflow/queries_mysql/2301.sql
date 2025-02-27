
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 10
), 
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.UpVotes) AS TotalUpVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
), 
PostsWithTags AS (
    SELECT 
        p.Id AS PostId,
        pt.Name AS PostType,
        GROUP_CONCAT(t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        (SELECT DISTINCT PostId, TagName FROM (
            SELECT p.Id AS PostId, TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS TagName
            FROM 
                (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
                 SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
                 SELECT 9 UNION ALL SELECT 10) AS numbers
            INNER JOIN Posts p ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1
        ) AS derived) t ON p.Id = t.PostId
    GROUP BY 
        p.Id, pt.Name
)
SELECT 
    r.PostId,
    r.Title,
    r.Score,
    r.CreationDate,
    us.TotalUpVotes,
    us.TotalPosts,
    pwt.PostType,
    pwt.Tags
FROM 
    RankedPosts r
LEFT JOIN 
    UserScores us ON r.OwnerUserId = us.UserId
JOIN 
    PostsWithTags pwt ON r.PostId = pwt.PostId
WHERE 
    r.PostRank <= 3
ORDER BY 
    r.Score DESC
LIMIT 100;
