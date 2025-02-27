WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN bc.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges bc ON u.Id = bc.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
PostActivity AS (
    SELECT 
        p.Id AS PostId, 
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        COUNT(pv.Id) AS TotalVotes,
        COUNT(c.Id) AS TotalComments,
        MAX(h.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags
    FROM 
        Posts p
    LEFT JOIN 
        Votes pv ON p.Id = pv.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory h ON p.Id = h.PostId
    LEFT JOIN 
        LATERAL string_to_array(p.Tags, ', ') AS tag_array ON true
    LEFT JOIN 
        Tags t ON tag_array::varchar = t.TagName
    WHERE 
        p.LastActivityDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.LastActivityDate
),
UserEngagement AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.TotalQuestions,
        ups.TotalAnswers,
        ups.TotalScore,
        ups.TotalViews,
        pa.TotalVotes,
        pa.TotalComments,
        pa.LastEditDate,
        pa.AssociatedTags
    FROM 
        UserPostStats ups
    LEFT JOIN 
        PostActivity pa ON ups.TotalPosts > 0
    ORDER BY 
        ups.TotalScore DESC
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalScore,
    TotalViews,
    TotalVotes,
    TotalComments,
    LastEditDate,
    AssociatedTags
FROM 
    UserEngagement
WHERE 
    TotalPosts > 5
LIMIT 100;
