
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        U.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 
),
TagsList AS (
    SELECT 
        p.Id AS PostId,
        GROUP_CONCAT(TRIM(tag) SEPARATOR ', ') AS Tags
    FROM 
        Posts p,
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) tag
         FROM 
         (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers 
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tags
    GROUP BY 
        p.Id
),
PostStats AS (
    SELECT 
        r.PostId,
        r.Title,
        r.OwnerDisplayName,
        r.CreationDate,
        r.Score,
        r.ViewCount,
        r.AnswerCount,
        t.Tags
    FROM 
        RankedPosts r
    JOIN 
        TagsList t ON r.PostId = t.PostId
    WHERE 
        r.RN = 1 
)

SELECT 
    ps.OwnerDisplayName,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.Tags,
    COALESCE(b.BadgeCount, 0) AS BadgeCount
FROM 
    PostStats ps
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
) b ON ps.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = b.UserId)
ORDER BY 
    ps.Score DESC, ps.CreationDate DESC
LIMIT 10;
