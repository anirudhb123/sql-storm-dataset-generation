WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS UsageCount,
        ROW_NUMBER() OVER (ORDER BY COUNT(pt.PostId) DESC) AS TagRank
    FROM 
        Tags t
    JOIN 
        Posts pt ON pt.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        pt.CreationDate >= NOW() - INTERVAL '30 days' 
    GROUP BY 
        t.TagName
),
PostHistoryLimit AS (
    SELECT 
        ph.PostId,
        STRING_AGG(ph.UserDisplayName || ' (' || ph.Comment || ')', '; ') AS EditDetails
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 24) -- Edit Title, Edit Body, Suggested Edit Applied
    GROUP BY 
        ph.PostId
),
Ranking AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.TotalQuestions,
        ups.TotalAnswers,
        ups.TotalScore,
        ups.LastPostDate,
        COALESCE(phe.EditDetails, 'No Edits') AS EditDetails,
        RANK() OVER (ORDER BY ups.TotalScore DESC) AS UserRank
    FROM 
        UserPostStats ups
    LEFT JOIN 
        PostHistoryLimit phe ON ups.UserId = phe.PostId
)

SELECT 
    r.UserId,
    r.DisplayName,
    r.TotalPosts,
    r.TotalQuestions,
    r.TotalAnswers,
    r.TotalScore,
    r.LastPostDate,
    r.EditDetails,
    t.TagName
FROM 
    Ranking r
LEFT JOIN 
    RecentPopularTags t ON r.TotalPosts > 10 AND t.TagRank <= 5
WHERE 
    r.UserRank <= 10
ORDER BY 
    r.TotalScore DESC, r.LastPostDate DESC;
