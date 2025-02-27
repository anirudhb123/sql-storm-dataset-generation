
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 1 YEAR) 
        AND p.Score > 0
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
TopComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(COALESCE(c.Score, 0)) AS TotalScore
    FROM 
        Comments c 
    GROUP BY 
        c.PostId
),
PostsWithTags AS (
    SELECT 
        p.Id AS PostId,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS TagsList
    FROM 
        Posts p
    LEFT JOIN 
        (
            SELECT 
                t.TagName 
            FROM 
                Tags t 
            JOIN 
                (SELECT DISTINCT tag FROM (
                    SELECT 
                        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1) AS tag
                    FROM 
                        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
                         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
                    WHERE 
                        CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1
                ) AS tags_array) AS t1 ON t.TagName = t1.tag
        ) t ON TRUE
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    ur.UserId,
    ur.Reputation,
    ur.BadgeCount,
    tc.CommentCount,
    tc.TotalScore,
    pt.TagsList
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON ur.UserId = (
        SELECT 
            p.OwnerUserId 
        FROM 
            Posts p 
        WHERE 
            p.Id = rp.PostId
    )
LEFT JOIN 
    TopComments tc ON tc.PostId = rp.PostId
LEFT JOIN 
    PostsWithTags pt ON pt.PostId = rp.PostId
WHERE 
    rp.ScoreRank <= 5
ORDER BY 
    rp.Score DESC,
    ur.Reputation DESC
LIMIT 100 OFFSET 0;
