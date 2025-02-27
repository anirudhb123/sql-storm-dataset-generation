WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
RecentPostLinks AS (
    SELECT 
        pl.PostId,
        pl.RelatedPostId,
        l.Name AS LinkTypeName,
        ROW_NUMBER() OVER (PARTITION BY pl.PostId ORDER BY pl.CreationDate DESC) AS rn
    FROM 
        PostLinks pl
    JOIN 
        LinkTypes l ON pl.LinkTypeId = l.Id
),
ClosedPostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT ph.UserId) AS CloseVoteCount,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId 
        AND ph.PostHistoryTypeId = 10
    GROUP BY 
        p.Id
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.QuestionCount,
    ups.AnswerCount,
    ups.AvgReputation,
    COALESCE(cps.CloseVoteCount, 0) AS TotalCloseVotes,
    cps.LastClosedDate,
    COALESCE(rpl.RelatedPostId, 0) AS RecentPostLink
FROM 
    UserPostStats ups
LEFT JOIN 
    ClosedPostStats cps ON ups.UserId = cps.PostId
LEFT JOIN 
    RecentPostLinks rpl ON rpl.PostId = (SELECT TOP 1 p.Id FROM Posts p WHERE p.OwnerUserId = ups.UserId ORDER BY p.CreationDate DESC) AND rpl.rn = 1
WHERE 
    ups.TotalPosts > 0
ORDER BY 
    ups.AvgReputation DESC
LIMIT 100
UNION ALL
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    0 AS TotalPosts,
    0 AS QuestionCount,
    0 AS AnswerCount,
    u.Reputation AS AvgReputation,
    0 AS TotalCloseVotes,
    NULL AS LastClosedDate,
    NULL AS RecentPostLink
FROM 
    Users u
WHERE 
    u.Reputation < 50
ORDER BY 
    AvgReputation DESC;
