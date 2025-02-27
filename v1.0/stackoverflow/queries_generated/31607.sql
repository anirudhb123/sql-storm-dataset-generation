WITH RecursivePostHierarchy AS (
    SELECT Id, ParentId, Title, CreationDate, OwnerUserId, 0 AS Level
    FROM Posts
    WHERE ParentId IS NULL
    UNION ALL
    SELECT p.Id, p.ParentId, p.Title, p.CreationDate, p.OwnerUserId, Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy rph ON p.ParentId = rph.Id
),
PostVoteSummary AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM Votes
    GROUP BY PostId
),
PostStatistics AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        COALESCE(ps.UpVotes, 0) AS UpVotes,
        COALESCE(ps.DownVotes, 0) AS DownVotes,
        COALESCE(ps.TotalVotes, 0) AS TotalVotes,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM Posts p
    LEFT JOIN PostVoteSummary ps ON p.Id = ps.PostId
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostsTags pt ON p.Id = pt.PostId
    LEFT JOIN Tags t ON pt.TagId = t.Id
    GROUP BY p.Id, p.Title, p.CreationDate, u.DisplayName
),
RecentActivity AS (
    SELECT 
        PostId,
        MAX(CreationDate) AS LastActivityDate
    FROM Comments
    GROUP BY PostId
),
PostFinal AS (
    SELECT 
        ps.*,
        ra.LastActivityDate,
        rh.Level AS PostLevel
    FROM PostStatistics ps
    LEFT JOIN RecentActivity ra ON ps.Id = ra.PostId
    LEFT JOIN RecursivePostHierarchy rh ON ps.Id = rh.Id
)
SELECT 
    pf.Id,
    pf.Title,
    pf.CreationDate,
    pf.UpVotes,
    pf.DownVotes,
    pf.TotalVotes,
    pf.OwnerDisplayName,
    pf.CommentCount,
    pf.Tags,
    pf.LastActivityDate,
    pf.PostLevel,
    COALESCE((SELECT COUNT(*) 
              FROM Posts p 
              WHERE p.ParentId = pf.Id), 0) AS AnswerCount,
    CASE 
        WHEN pf.LastActivityDate IS NULL THEN 'No Activity'
        ELSE DATE_TRUNC('minute', pf.LastActivityDate) 
    END AS LastActiveTime,
    (CASE 
        WHEN pf.OwnerDisplayName IS NULL THEN 'Anonymous'
        ELSE pf.OwnerDisplayName END) AS UserName
FROM PostFinal pf
ORDER BY pf.CreationDate DESC
LIMIT 100;
