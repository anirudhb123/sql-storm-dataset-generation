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
        p.PostTypeId = 1 -- Only questions
),
TagsList AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(TRIM(UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><'))), ', ') AS Tags
    FROM 
        Posts p
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
        r.RN = 1 -- Latest post for each user
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
