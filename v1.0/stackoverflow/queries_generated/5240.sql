WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS Upvotes,
        SUM(v.VoteTypeId = 3) AS Downvotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
        SUM(p.ViewCount) AS TotalViews
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2
    LEFT JOIN Votes v ON v.UserId = u.Id
    LEFT JOIN Badges b ON b.UserId = u.Id
    GROUP BY u.Id
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        AnswerCount,
        Upvotes,
        Downvotes,
        BadgeCount,
        TotalViews,
        RANK() OVER (ORDER BY TotalViews DESC, Upvotes DESC, QuestionCount DESC) AS EngagementRank
    FROM UserEngagement
)
SELECT 
    UserId,
    DisplayName,
    QuestionCount,
    AnswerCount,
    Upvotes,
    Downvotes,
    BadgeCount,
    TotalViews,
    EngagementRank
FROM RankedUsers
WHERE EngagementRank <= 10
ORDER BY EngagementRank;
