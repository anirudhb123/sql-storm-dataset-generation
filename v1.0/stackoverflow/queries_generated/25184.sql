WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount,
        AVG(p.Score) AS AverageScore
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>') OR p.Tags LIKE CONCAT('<', t.TagName, '>') OR p.Tags LIKE CONCAT('<', t.TagName, '%')
    GROUP BY 
        t.TagName
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    GROUP BY 
        u.Id
),
UserBadgeStatistics AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS HasGoldBadge,
        MAX(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS HasSilverBadge,
        MAX(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS HasBronzeBadge
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
UserTagEngagement AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT t.TagName) AS UniqueTagsEngaged,
        SUM(ts.TotalViews) AS TotalViewsFromTags,
        SUM(ts.PostCount) AS TotalPostsFromTags
    FROM 
        Users u
    JOIN 
        Posts p ON p.OwnerUserId = u.Id
    JOIN 
        (SELECT 
            t.TagName,
            COUNT(DISTINCT p.Id) AS PostCount
         FROM 
            Tags t
         JOIN 
            Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>') OR p.Tags LIKE CONCAT('<', t.TagName, '>') OR p.Tags LIKE CONCAT('<', t.TagName, '%')
         GROUP BY 
            t.TagName) ts ON p.Tags LIKE CONCAT('%<', ts.TagName, '>') OR p.Tags LIKE CONCAT('<', ts.TagName, '>') OR p.Tags LIKE CONCAT('<', ts.TagName, '%')
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    ur.Reputation,
    ts.TagName,
    ts.PostCount AS PostsLinkedToTag,
    ts.TotalViews AS TagTotalViews,
    ts.AverageScore AS TagAverageScore,
    ub.BadgeCount,
    ub.HasGoldBadge,
    ub.HasSilverBadge,
    ub.HasBronzeBadge,
    ue.UniqueTagsEngaged,
    ue.TotalViewsFromTags,
    ue.TotalPostsFromTags
FROM 
    Users u
JOIN 
    UserReputation ur ON u.Id = ur.UserId
JOIN 
    UserBadgeStatistics ub ON u.Id = ub.UserId
JOIN 
    UserTagEngagement ue ON u.Id = ue.UserId
LEFT JOIN 
    TagStatistics ts ON ts.PostCount > 0
ORDER BY 
    ur.Reputation DESC, ts.TotalViews DESC
LIMIT 10;
