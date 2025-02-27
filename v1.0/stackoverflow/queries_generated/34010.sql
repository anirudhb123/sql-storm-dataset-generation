WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId, 
        p.ParentId, 
        p.Title, 
        0 AS Level,
        p.OwnerUserId,
        COALESCE(u.DisplayName, 'Community') AS OwnerDisplayName,
        p.CreationDate
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        Level + 1,
        p.OwnerUserId,
        COALESCE(u.DisplayName, 'Community'),
        p.CreationDate
    FROM Posts p
    JOIN RecursivePostHierarchy r ON p.ParentId = r.PostId
)

, UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
)

, RecentVotes AS (
    SELECT 
        v.PostId, 
        vt.Name AS VoteType, 
        COUNT(v.Id) AS VoteCount
    FROM Votes v
    INNER JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE v.CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY v.PostId, vt.Name
)

SELECT 
    rph.PostId,
    rph.Title,
    rph.Level,
    rph.OwnerDisplayName,
    rph.CreationDate,
    upc.TotalPosts,
    upc.QuestionCount,
    upc.AnswerCount,
    COALESCE(rv.VoteCount, 0) AS RecentVoteCount,
    ARRAY_AGG(DISTINCT lt.Name) AS LinkTypes
FROM RecursivePostHierarchy rph
JOIN UserPostCounts upc ON rph.OwnerUserId = upc.UserId
LEFT JOIN RecentVotes rv ON rph.PostId = rv.PostId
LEFT JOIN PostLinks pl ON rph.PostId = pl.PostId
LEFT JOIN LinkTypes lt ON pl.LinkTypeId = lt.Id
GROUP BY rph.PostId, rph.Title, rph.Level, rph.OwnerDisplayName, rph.CreationDate, upc.TotalPosts, upc.QuestionCount, upc.AnswerCount, rv.VoteCount
ORDER BY rph.Level, RecentVoteCount DESC, rph.CreationDate DESC
LIMIT 100;
