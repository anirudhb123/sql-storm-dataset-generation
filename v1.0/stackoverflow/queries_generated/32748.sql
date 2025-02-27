WITH RECURSIVE TagHierarchy AS (
    SELECT Id, TagName, Count, ExcerptPostId, WikiPostId, 1 AS Level
    FROM Tags
    WHERE IsModeratorOnly = 0
    
    UNION ALL
    
    SELECT t.Id, t.TagName, t.Count, t.ExcerptPostId, t.WikiPostId, th.Level + 1
    FROM Tags t
    JOIN TagHierarchy th ON th.Id = t.WikiPostId
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    GROUP BY u.Id, u.DisplayName
),

PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        pt.Name AS PostType,
        COUNT(DISTINCT v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, pt.Name
)

SELECT 
    u.DisplayName AS User,
    ua.TotalViews,
    ua.TotalScore,
    ua.TotalPosts,
    ua.TotalComments,
    ph.PostId,
    ph.Title,
    ph.PostType,
    ph.TotalVotes,
    ph.UpVotes,
    ph.DownVotes,
    th.TagName,
    th.Level
FROM UserActivity ua
LEFT JOIN PostVoteSummary ph ON ua.UserId = ph.PostId
LEFT JOIN TagHierarchy th ON th.ExcerptPostId = ph.PostId
WHERE 
    ua.TotalPosts > 10
    AND ph.UpVotes > ph.DownVotes
ORDER BY ua.TotalViews DESC, ua.TotalScore DESC;

