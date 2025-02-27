
WITH tagged_posts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p
    JOIN 
        (SELECT @row := @row + 1 AS n FROM (SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers, (SELECT @row := 0) r) numbers 
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1 
), tag_stats AS (
    SELECT 
        Tag,
        COUNT(DISTINCT PostId) AS PostCount,
        COUNT(DISTINCT CASE WHEN p.OwnerUserId IS NOT NULL THEN p.OwnerUserId END) AS UniqueUserCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        tagged_posts t
    JOIN 
        Posts p ON t.PostId = p.Id
    GROUP BY 
        Tag
), user_badges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), most_active_users AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.OwnerUserId
    ORDER BY 
        PostCount DESC
    LIMIT 10
), comprehensive_report AS (
    SELECT 
        t.Tag,
        t.PostCount,
        t.UniqueUserCount,
        t.LastPostDate,
        u.BadgeCount,
        COALESCE(a.PostCount, 0) AS ActivePostCount
    FROM 
        tag_stats t
    LEFT JOIN 
        user_badges u ON u.UserId = t.UniqueUserCount
    LEFT JOIN 
        most_active_users a ON u.UserId = a.OwnerUserId
)
SELECT 
    Tag,
    PostCount,
    UniqueUserCount,
    LastPostDate,
    BadgeCount,
    ActivePostCount
FROM 
    comprehensive_report
ORDER BY 
    PostCount DESC, 
    UniqueUserCount DESC;
