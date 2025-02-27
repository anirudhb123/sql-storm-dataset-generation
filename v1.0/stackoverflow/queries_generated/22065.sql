WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        SUM(v.Id IS NOT NULL) AS TotalVotes,
        ROW_NUMBER() OVER (ORDER BY COUNT(p.Id) DESC) AS ActivityRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.CreationDate < NOW() - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
),
QuestionStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS TotalQuestions,
        AVG(EXTRACT(EPOCH FROM (p.LastActivityDate - p.CreationDate)) / 3600) AS AvgHoursToResponse
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND p.ClosedDate IS NULL
    GROUP BY 
        p.OwnerUserId
),
BadgesCount AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS AwardedBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    ua.DisplayName,
    ua.TotalPosts,
    ua.Questions,
    ua.Answers,
    ua.TotalBounties,
    qa.TotalQuestions,
    qa.AvgHoursToResponse,
    bc.BadgeCount,
    COALESCE(bc.AwardedBadges, 'None') AS AwardedBadges
FROM 
    UserActivity ua
LEFT JOIN 
    QuestionStatistics qa ON ua.UserId = qa.OwnerUserId
LEFT JOIN 
    BadgesCount bc ON ua.UserId = bc.UserId
WHERE 
    ua.TotalPosts > 0
ORDER BY 
    ua.TotalPosts DESC
LIMIT 10
UNION ALL
SELECT 
    'Aggregate Data' AS DisplayName,
    SUM(TotalPosts),
    SUM(Questions),
    SUM(Answers),
    SUM(TotalBounties),
    SUM(TotalQuestions),
    AVG(AvgHoursToResponse),
    SUM(BadgeCount),
    STRING_AGG(AwardedBadges, '; ') 
FROM (
    SELECT 
        ua.TotalPosts,
        ua.Questions,
        ua.Answers,
        ua.TotalBounties,
        qa.TotalQuestions,
        qa.AvgHoursToResponse,
        bc.BadgeCount,
        COALESCE(bc.AwardedBadges, 'None') AS AwardedBadges
    FROM 
        UserActivity ua
    LEFT JOIN 
        QuestionStatistics qa ON ua.UserId = qa.OwnerUserId
    LEFT JOIN 
        BadgesCount bc ON ua.UserId = bc.UserId
    WHERE 
        ua.TotalPosts > 0
) AS SummaryTable;
