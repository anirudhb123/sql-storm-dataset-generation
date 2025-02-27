
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT DISTINCT tag.TagName
         FROM (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1)) AS TagName
               FROM (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
                     UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 
                     UNION SELECT 9 UNION SELECT 10) numbers
               WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1) AS tag
        ) AS t ON TRUE
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
TopQuestions AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        ViewCount,
        Score,
        OwnerName,
        CommentCount,
        Tags
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10 
),
UserBadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    tq.Title,
    tq.Body,
    tq.CreationDate,
    tq.ViewCount,
    tq.Score,
    tq.OwnerName,
    tq.CommentCount,
    tq.Tags,
    ub.BadgeCount,
    ub.GoldBadgeCount,
    ub.SilverBadgeCount,
    ub.BronzeBadgeCount
FROM 
    TopQuestions tq
JOIN 
    UserBadgeCounts ub ON tq.OwnerName = (SELECT DisplayName FROM Users WHERE Id = ub.UserId)
ORDER BY 
    tq.ViewCount DESC, 
    tq.Score DESC;
