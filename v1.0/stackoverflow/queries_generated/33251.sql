WITH RecursivePosts AS (
    -- Recursive CTE to get the hierarchy of posts and their associated answer counts
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        p.CreationDate,
        COALESCE(a.AnswerCount, 0) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT ParentId, COUNT(*) AS AnswerCount 
         FROM Posts 
         WHERE PostTypeId = 2 
         GROUP BY ParentId) a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1
    UNION ALL
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        p.CreationDate,
        COALESCE(a.AnswerCount, 0) AS AnswerCount
    FROM 
        Posts p
    INNER JOIN 
        RecursivePosts r ON p.ParentId = r.PostId
    LEFT JOIN 
        (SELECT ParentId, COUNT(*) AS AnswerCount 
         FROM Posts 
         WHERE PostTypeId = 2 
         GROUP BY ParentId) a ON p.Id = a.ParentId
), PostVoteStats AS (
    -- Aggregating vote statistics of posts
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
), UserBadges AS (
    -- Getting user badges and their counts
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.Title AS QuestionTitle,
    rp.CreationDate AS QuestionDate,
    u.DisplayName AS AskedBy,
    u.Location,
    pvs.UpVotes,
    pvs.DownVotes,
    ub.BadgeCount,
    ub.BadgeNames,
    rp.AnswerCount AS TotalAnswers
FROM 
    RecursivePosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    PostVoteStats pvs ON rp.PostId = pvs.PostId
JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    rp.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    AND (rp.AnswerCount > 0 OR pvs.UpVotes > 0)
ORDER BY 
    rp.CreationDate DESC
LIMIT 100;

-- Using this query to benchmark performance on queries involving complex relationships 
-- and aggregations across several tables using CTEs, window functions, and correlated subqueries.
