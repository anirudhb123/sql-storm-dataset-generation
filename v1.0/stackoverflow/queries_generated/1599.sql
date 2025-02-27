WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(Tags, ',')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        TagName
),
TopPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.Score > 0
)
SELECT 
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalScore,
    COALESCE(pt.TagName, 'No Tags') AS PopularTag,
    tp.Title AS TopPostTitle,
    tp.CreationDate AS TopPostDate
FROM 
    UserPostStats ups
LEFT JOIN 
    (SELECT TagName FROM PopularTags ORDER BY TagCount DESC LIMIT 1) pt ON TRUE
LEFT JOIN 
    TopPosts tp ON ups.TotalPosts > 0
WHERE 
    ups.TotalScore > (SELECT AVG(TotalScore) FROM UserPostStats)
ORDER BY 
    ups.TotalPosts DESC, ups.TotalScore DESC;
