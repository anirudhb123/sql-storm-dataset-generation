WITH RecursivePostHierarchy AS (
    -- CTE to get all answers and their related questions in a hierarchical manner
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions
    UNION ALL
    SELECT 
        a.Id AS PostId,
        a.Title,
        a.ParentId,
        rh.Level + 1 AS Level
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostHierarchy rh ON a.ParentId = rh.PostId
    WHERE 
        a.PostTypeId = 2 -- Answers
),
VotesWithType AS (
    -- CTE to calculate the total votes and categorize them
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    INNER JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
UserBadges AS (
    -- CTE to summarize user badges
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass -- Assuming higher number means better badge
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
RecentActivity AS (
    -- CTE to get posts with the last activity date, along with the total number of comments
    SELECT 
        p.Id AS PostId,
        p.LastActivityDate,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.LastActivityDate
)
-- Final selection combining all CTEs
SELECT 
    p.Title AS QuestionTitle,
    COUNT(DISTINCT p.Id) AS TotalQuestions,
    COALESCE(v.UpVotes, 0) AS TotalUpVotes,
    COALESCE(v.DownVotes, 0) AS TotalDownVotes,
    u.BadgeCount,
    u.HighestBadgeClass,
    ra.LastActivityDate,
    ra.CommentCount
FROM 
    RecursivePostHierarchy p
LEFT JOIN 
    VotesWithType v ON p.PostId = v.PostId
JOIN 
    Users u ON p.PostId = u.Id -- Assuming 'OwnerUserId' might be the user ID, this may need adjustment
LEFT JOIN 
    RecentActivity ra ON p.PostId = ra.PostId
GROUP BY 
    p.Title, v.UpVotes, v.DownVotes, u.BadgeCount, u.HighestBadgeClass, ra.LastActivityDate, ra.CommentCount
ORDER BY 
    TotalUpVotes DESC, TotalDownVotes ASC;
