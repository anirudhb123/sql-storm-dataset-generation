WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        AVG(b.Class) AS AvgBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),

PopularTags AS (
    SELECT 
        TRIM(SUBSTRING(t.TagName, 2, LENGTH(t.TagName) - 2)) AS TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 10
    ORDER BY 
        PostCount DESC
),

UserPosts AS (
    SELECT 
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0
    GROUP BY 
        p.OwnerUserId, p.Title, p.CreationDate
),

BenchmarkResults AS (
    SELECT 
        u.DisplayName AS UserAlias,
        ub.BadgeCount,
        ub.AvgBadgeClass,
        COUNT(up.Title) AS PostCount,
        SUM(up.CommentCount) AS TotalComments,
        (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = u.Id AND p.Score > 0) AS HighScoringPosts
    FROM 
        UserBadges ub
    JOIN 
        UserPosts up ON ub.UserId = up.OwnerUserId
    JOIN 
        Users u ON ub.UserId = u.Id
    GROUP BY 
        u.DisplayName, ub.BadgeCount, ub.AvgBadgeClass
)

SELECT 
    br.UserAlias,
    br.BadgeCount,
    br.AvgBadgeClass,
    br.PostCount,
    br.TotalComments,
    br.HighScoringPosts,
    pt.TagName
FROM 
    BenchmarkResults br
JOIN 
    PopularTags pt ON pt.PostCount > 20
ORDER BY 
    br.BadgeCount DESC, br.TotalComments DESC, br.PostCount DESC;
