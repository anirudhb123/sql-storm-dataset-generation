WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Ranking
    FROM 
        Users u
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS NetVotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS HistoryCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.OwnerUserId
),
UserActivity AS (
    SELECT 
        ur.UserId,
        COUNT(ps.PostId) AS TotalPosts,
        SUM(ps.CommentCount) AS TotalComments,
        AVG(ps.NetVotes) AS AverageNetVotes,
        MAX(ps.NetVotes) AS HighestNetVotes
    FROM 
        UserReputation ur
    JOIN 
        PostStats ps ON ur.UserId = ps.OwnerUserId
    GROUP BY 
        ur.UserId
)
SELECT 
    ua.UserId,
    ua.TotalPosts,
    ua.TotalComments,
    ua.AverageNetVotes,
    ua.HighestNetVotes,
    ur.Ranking
FROM 
    UserActivity ua
JOIN 
    UserReputation ur ON ua.UserId = ur.UserId
WHERE 
    ua.TotalPosts > 0
ORDER BY 
    ur.Ranking ASC,
    ua.TotalComments DESC
LIMIT 10;

WITH RECURSIVE TagHierarchy AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        1 AS Level
    FROM 
        Tags t
    WHERE 
        t.IsModeratorOnly = 0
    UNION ALL
    SELECT 
        t.Id,
        t.TagName,
        th.Level + 1
    FROM 
        Tags t
    JOIN 
        TagHierarchy th ON t.ExcerptPostId = th.TagId
)
SELECT 
    th.TagId,
    th.TagName,
    th.Level,
    COUNT(p.Id) AS PostCount
FROM 
    TagHierarchy th
LEFT JOIN 
    Posts p ON p.Tags LIKE '%' || th.TagName || '%'
GROUP BY 
    th.TagId, th.TagName, th.Level
HAVING 
    COUNT(p.Id) > 5;

SELECT 
    t.TagName,
    COUNT(DISTINCT p.Id) AS NumberOfPosts
FROM 
    Tags t
JOIN 
    Posts p ON p.Tags LIKE '%' || t.TagName || '%'
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    ph.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY 
    t.TagName
ORDER BY 
    NumberOfPosts DESC
LIMIT 5;
