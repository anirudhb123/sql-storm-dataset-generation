WITH ProcessedTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '>')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),

TagUsage AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        ProcessedTags
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
),

UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),

UserPostActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId IN (10, 12) THEN 1 ELSE 0 END) AS ClosedCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),

UserActivityWithBadges AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.PostCount,
        ua.QuestionCount,
        ua.AnswerCount,
        ua.ClosedCount,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount
    FROM 
        UserPostActivity ua
    LEFT JOIN 
        UserBadgeCounts ub ON ua.UserId = ub.UserId
)

SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.PostCount,
    ua.QuestionCount,
    ua.AnswerCount,
    ua.ClosedCount,
    ua.BadgeCount,
    tt.Tag,
    tt.TagCount
FROM 
    UserActivityWithBadges ua
JOIN 
    TagUsage tt ON tt.Tag IN (
        SELECT 
            unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '>')) 
        FROM 
            Posts p 
        WHERE 
            p.OwnerUserId = ua.UserId AND p.PostTypeId = 1
    )
ORDER BY 
    ua.BadgeCount DESC, 
    ua.PostCount DESC;
