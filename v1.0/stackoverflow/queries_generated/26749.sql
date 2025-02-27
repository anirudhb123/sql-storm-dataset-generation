WITH TagCounts AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(ps.Score) AS TotalScore,
        SUM(ps.ViewCount) AS TotalViews
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN 
        Posts ps ON p.Id = ps.Id
    GROUP BY 
        t.TagName
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(u.Reputation) AS TotalReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(ut.DisplayName, 'Anonymous') AS LastEditor,
        pt.Name AS TypeName
    FROM 
        Posts p
    LEFT JOIN 
        Users ut ON p.LastEditorUserId = ut.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
)
SELECT 
    tc.TagName,
    tc.PostCount,
    tc.TotalScore,
    tc.TotalViews,
    ur.DisplayName AS UserWithMostBadges,
    ur.BadgeCount,
    ur.TotalReputation,
    ps.Id AS PostId,
    ps.Title,
    ps.Body,
    ps.CreationDate,
    ps.ViewCount,
    ps.AnswerCount,
    ps.LastEditor,
    ps.TypeName
FROM 
    TagCounts tc
JOIN 
    UserReputation ur ON ur.BadgeCount = (SELECT MAX(BadgeCount) FROM UserReputation)
JOIN 
    PostStatistics ps ON ps.ViewCount BETWEEN 100 AND 1000
WHERE 
    tc.PostCount > 5
ORDER BY 
    tc.TotalScore DESC, 
    ur.TotalReputation DESC;
