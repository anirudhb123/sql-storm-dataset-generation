WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName AS UserDisplayName,
        u.Reputation,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        AVG(p.Score) AS AvgScore,
        ARRAY_AGG(DISTINCT SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2) ORDER BY p.CreationDate) AS UniqueTags,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RecentActivity AS (
    SELECT 
        u.Id AS UserId,
        MAX(p.CreationDate) AS LastPostDate,
        COUNT(c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id
),
MergedStats AS (
    SELECT 
        ups.UserId,
        ups.UserDisplayName,
        ups.Reputation,
        ups.TotalPosts,
        ups.QuestionCount,
        ups.AnswerCount,
        ups.TotalViews,
        ups.TotalScore,
        ups.AvgScore,
        ups.UniqueTags,
        ra.LastPostDate,
        ra.TotalComments,
        CASE 
            WHEN ups.Reputation >= 1000 THEN 'Experienced'
            WHEN ups.Reputation >= 100 THEN 'Intermediate'
            ELSE 'Novice'
        END AS UserLevel
    FROM 
        UserPostStats ups
    LEFT JOIN 
        RecentActivity ra ON ups.UserId = ra.UserId
)
SELECT 
    UserDisplayName,
    TotalPosts,
    QuestionCount,
    AnswerCount,
    TotalViews,
    TotalScore,
    AvgScore,
    UniqueTags,
    LastPostDate,
    TotalComments,
    UserLevel
FROM 
    MergedStats
WHERE 
    TotalPosts > 5
ORDER BY 
    TotalScore DESC,
    LastPostDate DESC
LIMIT 10;
