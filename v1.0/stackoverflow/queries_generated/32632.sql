WITH RECURSIVE UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.Score > 0 THEN p.Score ELSE 0 END) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
), 
RecentUserActivity AS (
    SELECT 
        UserId,
        MAX(CreationDate) AS LastActivityDate
    FROM 
        Comments 
    GROUP BY 
        UserId
),
BadgeStats AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(Name, ', ') AS BadgeNames
    FROM 
        Badges 
    GROUP BY 
        UserId
),
PostHistorySummary AS (
    SELECT 
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.OwnerUserId
)

SELECT 
    u.DisplayName,
    u.Reputation,
    u.Views,
    COALESCE(up.PostCount, 0) AS TotalPosts,
    COALESCE(up.QuestionCount, 0) AS TotalQuestions,
    COALESCE(up.AnswerCount, 0) AS TotalAnswers,
    COALESCE(up.TotalScore, 0) AS TotalScore,
    COALESCE(r.LastActivityDate, 'No Activity') AS LastCommentDate,
    COALESCE(bs.BadgeCount, 0) AS TotalBadges,
    COALESCE(bs.BadgeNames, 'No Badges') AS BadgeNames,
    COALESCE(ph.CommentCount, 0) AS TotalPostComments,
    COALESCE(ph.EditCount, 0) AS TotalEdits,
    COALESCE(ph.LastEditDate, 'Never Edited') AS LastEditedPost
FROM 
    Users u
LEFT JOIN 
    UserPostStats up ON u.Id = up.UserId
LEFT JOIN 
    RecentUserActivity r ON u.Id = r.UserId
LEFT JOIN 
    BadgeStats bs ON u.Id = bs.UserId
LEFT JOIN 
    PostHistorySummary ph ON u.Id = ph.OwnerUserId
WHERE 
    u.Reputation > 100
ORDER BY 
    u.Reputation DESC;
