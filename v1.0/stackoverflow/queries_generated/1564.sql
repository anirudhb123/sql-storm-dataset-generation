WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        Questions,
        Answers,
        PositivePosts,
        AvgViewCount,
        RANK() OVER (ORDER BY TotalPosts DESC) AS RankTotalPosts,
        RANK() OVER (ORDER BY PositivePosts DESC) AS RankPositivePosts
    FROM 
        UserPostStats
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    CROSS JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS t(TagName)
    GROUP BY 
        p.Id
),
UserPostDetails AS (
    SELECT 
        u.DisplayName,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(pt.Tags, 'No Tags') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostTags pt ON p.Id = pt.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
)
SELECT 
    u.DisplayName,
    up.TotalPosts,
    up.Questions,
    up.Answers,
    up.PositivePosts,
    up.AvgViewCount,
    ups.RankTotalPosts,
    ups.RankPositivePosts,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.Tags
FROM 
    TopUsers ups
JOIN 
    UserPostStats up ON ups.UserId = up.UserId
LEFT JOIN 
    UserPostDetails pd ON ups.UserId = pd.DisplayName
WHERE 
    (ups.RankTotalPosts <= 10 OR ups.RankPositivePosts <= 10)
    AND (pd.PostRank <= 5 OR pd.PostRank IS NULL)
ORDER BY 
    ups.RankTotalPosts, ups.RankPositivePosts;
