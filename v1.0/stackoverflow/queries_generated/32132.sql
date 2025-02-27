WITH RecursiveTagHierarchy AS (
    SELECT 
        Id,
        TagName,
        Count,
        ExcerptPostId,
        WikiPostId,
        IsModeratorOnly,
        IsRequired,
        0 AS Level
    FROM 
        Tags
    WHERE 
        IsModeratorOnly = 1

    UNION ALL

    SELECT 
        t.Id,
        t.TagName,
        t.Count,
        t.ExcerptPostId,
        t.WikiPostId,
        t.IsModeratorOnly,
        t.IsRequired,
        rth.Level + 1
    FROM 
        Tags t
    INNER JOIN 
        RecursiveTagHierarchy rth ON rth.Id = t.ExcerptPostId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS QuestionCount,
    SUM(p.Score) AS TotalScore,
    AVG(p.Score) AS AverageScore,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags,
    COALESCE(MAX(b.Date), 'No Badges') AS LatestBadge,
    CASE 
        WHEN AVG(p.ViewCount) > 1000 THEN 'High Engagement'
        ELSE 'Normal Engagement'
    END AS EngagementLevel
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    Posts p2 ON p.Id = p2.AcceptedAnswerId
LEFT JOIN 
    RecursiveTagHierarchy rth ON p.Tags LIKE '%' + rth.TagName + '%'
WHERE 
    u.Reputation > 50
GROUP BY 
    u.Id, u.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) > 10
ORDER BY 
    TotalScore DESC;

WITH RecentVotes AS (
    SELECT 
        v.PostId,
        v.UserId,
        v.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY v.PostId ORDER BY v.CreationDate DESC) AS RowNum
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '30 days'
)
SELECT 
    p.Title,
    COUNT(DISTINCT rv.UserId) AS RecentVoterCount,
    SUM(CASE WHEN rv.RowNum = 1 THEN 1 ELSE 0 END) AS LatestVote,
    SUM(v.VoteTypeId) AS TotalVotes
FROM 
    Posts p
LEFT JOIN 
    RecentVotes rv ON p.Id = rv.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId 
WHERE 
    p.CreationDate >= NOW() - INTERVAL '30 days'
GROUP BY 
    p.Title
ORDER BY 
    RecentVoterCount DESC;
