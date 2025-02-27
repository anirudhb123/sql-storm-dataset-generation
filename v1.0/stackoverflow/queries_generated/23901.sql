WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
PopularTags AS (
    SELECT 
        LATERAL unnest(string_to_array(Tags, '><')) AS Tag
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tag
),
TagEngagement AS (
    SELECT 
        ut.Tag,
        COUNT(p.Id) AS PostsCount,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViews,
        COUNT(DISTINCT ue.UserId) AS EngagedUsers
    FROM 
        PopularTags ut
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || ut.Tag || '%'
    LEFT JOIN 
        UserEngagement ue ON p.OwnerUserId = ue.UserId
    GROUP BY 
        ut.Tag
),
TagRanked AS (
    SELECT 
        Tag,
        PostsCount,
        AvgViews,
        EngagedUsers,
        RANK() OVER (ORDER BY PostsCount DESC, AvgViews DESC) AS TagRank
    FROM 
        TagEngagement
)
SELECT 
    ue.DisplayName,
    ue.TotalPosts,
    ue.TotalUpvotes,
    ue.TotalDownvotes,
    ue.GoldBadges,
    ue.SilverBadges,
    ue.BronzeBadges,
    tr.Tag,
    tr.PostsCount,
    tr.AvgViews,
    tr.EngagedUsers,
    tr.TagRank
FROM 
    UserEngagement ue
JOIN 
    TagRanked tr ON ue.TotalPosts > 0
WHERE 
    ue.TotalUpvotes > COALESCE(ue.TotalDownvotes, 0) 
    AND tr.TagRank <= 10
ORDER BY 
    ue.TotalUpvotes DESC, 
    tr.PostsCount DESC;
