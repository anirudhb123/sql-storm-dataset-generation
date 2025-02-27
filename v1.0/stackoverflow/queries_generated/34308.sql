WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions
    UNION ALL
    SELECT 
        a.Id AS PostId,
        a.Title,
        a.CreationDate,
        a.OwnerUserId,
        a.AcceptedAnswerId,
        Level + 1
    FROM 
        Posts a
    JOIN 
        RecursiveCTE r ON a.ParentId = r.PostId
)
, UserBadges AS (
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
, PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
)
SELECT 
    r.Title,
    r.CreationDate,
    u.DisplayName AS PostOwner,
    ub.BadgeCount,
    ub.BadgeNames,
    pm.CommentCount,
    pm.UpVotes,
    pm.DownVotes,
    CASE 
        WHEN (pm.UpVotes - pm.DownVotes) > 0 THEN 'Positive'
        WHEN (pm.UpVotes - pm.DownVotes) < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    RecursiveCTE r
JOIN 
    Users u ON r.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostMetrics pm ON r.PostId = pm.PostId
WHERE 
    r.Level = 1 -- Only top-level questions
ORDER BY 
    r.CreationDate DESC
LIMIT 100;

This SQL query performs several advanced tasks, including recursive common table expressions to find questions and their accepted answers, summarizing user badge data, and capturing post metrics such as comment counts and vote tallies. It uses known constructs and incorporates outer joins, aggregations, string aggregations, and complex conditional logic to provide a detailed overview of the top-level questions.
