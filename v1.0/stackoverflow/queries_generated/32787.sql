WITH RecursivePostChain AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        p.CreationDate,
        0 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Starting from Questions
    UNION ALL
    SELECT 
        a.Id AS PostId,
        a.Title,
        a.OwnerUserId,
        a.PostTypeId,
        a.CreationDate,
        rpc.Level + 1
    FROM Posts a
    INNER JOIN RecursivePostChain rpc ON a.ParentId = rpc.PostId
),
PostMetrics AS (
    SELECT 
        p.Id,
        p.Title,
        u.DisplayName AS OwnerName,
        p.CreationDate,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        COALESCE(AVG(CHAR_LENGTH(c.Text)), 0) AS AvgCommentLength,
        COALESCE(COUNT(c.Id), 0) AS TotalComments,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        RANK() OVER (ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY p.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        PostId,
        COUNT(*) AS RelatedPostCount
    FROM PostLinks
    WHERE LinkTypeId = 1 -- Linked posts
    GROUP BY PostId
),
FinalMetrics AS (
    SELECT 
        pm.Id,
        pm.Title,
        pm.OwnerName,
        pm.CreationDate,
        pm.UpVotes,
        pm.DownVotes,
        pm.AvgCommentLength,
        pm.TotalComments,
        COALESCE(ps.RelatedPostCount, 0) AS LinkedPostCount,
        CASE 
            WHEN pm.UpVotes - pm.DownVotes > 10 THEN 'Hot Topic'
            WHEN pm.TotalComments > 5 THEN 'Engaged'
            ELSE 'Standard Post'
        END AS PostCategory
    FROM PostMetrics pm
    LEFT JOIN PostStats ps ON pm.Id = ps.PostId
)
SELECT 
    f.Title,
    f.OwnerName,
    f.CreationDate,
    f.UpVotes,
    f.DownVotes,
    f.AvgCommentLength,
    f.TotalComments,
    f.LinkedPostCount,
    f.PostCategory,
    CASE 
        WHEN f.LinkedPostCount > 5 THEN 'High Link Activity'
        ELSE 'Normal Activity'
    END AS ActivityLevel
FROM FinalMetrics f
WHERE f.CreationDate < (CURRENT_TIMESTAMP - INTERVAL '30 days')
ORDER BY f.UpVotes - f.DownVotes DESC, f.TotalComments DESC
LIMIT 100;
