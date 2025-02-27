
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
UserReputation AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        CASE 
            WHEN u.LastAccessDate < NOW() - INTERVAL 30 DAY THEN 'Inactive'
            ELSE 'Active'
        END AS UserStatus
    FROM 
        Users u
), 
PostTags AS (
    SELECT 
        p.Id AS PostId,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags 
    FROM 
        Posts p
    JOIN 
        (
            SELECT 
                p.Id, 
                SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS tag_name
            FROM 
                Posts p
            INNER JOIN 
                (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
                 SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
                 SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
        ) AS tag
    JOIN 
        Tags t ON t.TagName = tag.tag_name
    GROUP BY 
        p.Id
)
SELECT
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    CASE 
        WHEN ur.UserStatus = 'Active' AND rp.CommentCount > 5 THEN 'High Engagement'
        WHEN ur.UserStatus = 'Inactive' AND rp.CommentCount <= 5 THEN 'Low Engagement'
        ELSE 'Moderate Engagement'
    END AS EngagementLevel,
    ur.UserStatus,
    pt.Tags
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.Id
LEFT JOIN 
    PostTags pt ON rp.Id = pt.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.Score DESC
LIMIT 50;
