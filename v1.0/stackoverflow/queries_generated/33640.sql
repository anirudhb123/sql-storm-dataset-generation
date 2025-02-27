WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        CreationDate,
        1 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(v.BountyAmount) AS TotalBounty,
        AVG(COALESCE(v.CreationDate, CURRENT_TIMESTAMP) - p.CreationDate) AS AvgResponseTime
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 -- Questions
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id -- Answers
    LEFT JOIN 
        Votes v ON v.UserId = u.Id AND v.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2) -- Questions and Answers
    GROUP BY 
        p.Id
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.QuestionCount,
    u.AnswerCount,
    u.TotalBounty,
    u.AvgResponseTime,
    ph.Level AS PostHierarchyLevel,
    COUNT(DISTINCT p.Id) AS AssociatedPosts,
    COALESCE(v.UpVotes, 0) AS PostUpVotes,
    COALESCE(v.DownVotes, 0) AS PostDownVotes,
    COALESCE(v.TotalVotes, 0) AS TotalPostVotes
FROM 
    UserActivity u
JOIN 
    RecursivePostHierarchy ph ON u.QuestionCount > 0
LEFT JOIN 
    Posts p ON ph.Id = p.ParentId OR ph.Id = p.Id
LEFT JOIN 
    PostVoteStats v ON v.PostId = p.Id
GROUP BY 
    u.UserId, u.DisplayName, u.QuestionCount, u.AnswerCount, 
    u.TotalBounty, u.AvgResponseTime, ph.Level
HAVING 
    AVG(u.AvgResponseTime) < interval '1 hour' AND 
    SUM(u.QuestionCount) >= 5
ORDER BY 
    TotalPostVotes DESC, AvgResponseTime ASC
LIMIT 100;
