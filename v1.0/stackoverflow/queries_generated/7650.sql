WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS TotalComments
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.Id) AS TagCount
    FROM 
        Tags t
    JOIN 
        Posts pt ON pt.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadges,
        SUM(p.ViewCount) AS TotalPostViews,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
UserEngagement AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalBadges,
        us.TotalPostViews,
        us.TotalQuestions,
        us.TotalAnswers,
        RANK() OVER (ORDER BY us.TotalPostViews DESC) AS EngagementRank
    FROM 
        UserStats us
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.OwnerDisplayName,
    rp.TotalComments,
    tt.TagName,
    ue.DisplayName AS EngagedUser,
    ue.TotalBadges,
    ue.TotalPostViews,
    ue.EngagementRank
FROM 
    RecentPosts rp
JOIN 
    TopTags tt ON rp.Title ILIKE '%' || tt.TagName || '%'
JOIN 
    UserEngagement ue ON ue.TotalPostViews > 0
WHERE 
    rp.TotalComments > 0
ORDER BY 
    rp.Score DESC, ue.TotalPostViews DESC;
