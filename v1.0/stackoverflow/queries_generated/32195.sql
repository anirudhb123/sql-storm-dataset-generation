WITH RECURSIVE PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS PopularityRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
),
RecentUserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBountyAmount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.CreationDate >= NOW() - INTERVAL '60 days'
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id AND v.CreationDate >= NOW() - INTERVAL '60 days'
    GROUP BY 
        u.Id, u.DisplayName
),
HighRankingPosts AS (
    SELECT 
        pp.Id,
        pp.Title,
        pp.ViewCount,
        pp.Score,
        ua.UserId,
        ua.DisplayName,
        ROW_NUMBER() OVER (PARTITION BY ua.UserId ORDER BY pp.Score DESC) AS UserPostRank
    FROM 
        PopularPosts pp
    JOIN 
        RecentUserActivity ua ON pp.Score > 10
)
SELECT 
    h.Id AS HighRankingPostId,
    h.Title AS HighRankingPostTitle,
    h.ViewCount AS HighRankingPostViewCount,
    h.Score AS HighRankingPostScore,
    u.DisplayName AS UserDisplayName,
    CASE
        WHEN ua.PostsCreated > 0 THEN 'Active User'
        ELSE 'Inactive User'
    END AS UserStatus
FROM 
    HighRankingPosts h
JOIN 
    RecentUserActivity ua ON h.UserId = ua.UserId
JOIN 
    Users u ON u.Id = h.UserId
WHERE 
    UserPostRank <= 5
ORDER BY 
    h.Score DESC, u.Reputation DESC;

-- Additionally, demonstrate aggregation of tagging for the accumulated posts
SELECT
    t.TagName,
    COUNT(p.Id) AS PostCount,
    SUM(p.ViewCount) AS TotalViews,
    AVG(p.Score) AS AverageScore
FROM 
    Posts p
JOIN 
    unnest(string_to_array(p.Tags, '><')) AS tag_t(tag) ON t.TagName = tag_t.tag
JOIN 
    Tags t ON t.TagName = tag_t.tag
WHERE 
    p.CreationDate >= NOW() - INTERVAL '90 days'
GROUP BY 
    t.TagName
HAVING 
    COUNT(p.Id) > 10
ORDER BY 
    TotalViews DESC;
