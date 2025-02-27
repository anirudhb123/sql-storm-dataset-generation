
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01 12:34:56', INTERVAL 1 YEAR) 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', numbers.n), '>', -1) AS TagName, 
        COUNT(*) AS TagCount
    FROM 
        Posts 
    INNER JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
        UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '>', '')) >= numbers.n - 1
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 5
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        COUNT(DISTINCT p.Id) AS PostsCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    rp.PostId, 
    rp.Title, 
    rp.CreationDate, 
    rp.Score,
    rp.ViewCount,
    COALESCE(ut.PostsCount, 0) AS UserPostCount,
    pt.TagName,
    pt.TagCount
FROM 
    RankedPosts rp
LEFT JOIN 
    UserReputation ut ON rp.PostId = (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ut.UserId LIMIT 1)
LEFT JOIN 
    PopularTags pt ON FIND_IN_SET(pt.TagName, rp.Title) > 0
WHERE 
    rp.RankScore <= 10
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
