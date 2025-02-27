WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with Questions
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
)

SELECT 
    q.Title AS QuestionTitle,
    COUNT(DISTINCT a.Id) AS AnswerCount,
    SUM(COALESCE(v.VoteCount, 0)) AS TotalVotes,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    MAX(b.Date) AS LatestBadgeDate,
    CONCAT(u.DisplayName, ' (', u.Reputation, ' reputation)') AS UserInfo
FROM 
    Posts q
LEFT JOIN 
    Posts a ON q.Id = a.ParentId AND a.PostTypeId = 2  -- Join Answers
LEFT JOIN 
    Votes v ON q.Id = v.PostId AND v.VoteTypeId = 2  -- Upvotes
LEFT JOIN 
    Tags t ON t.Id = ANY(string_to_array(substring(q.Tags, 2, length(q.Tags)-2), '><')::int[])  -- Join Tags
LEFT JOIN 
    Users u ON q.OwnerUserId = u.Id  -- Owner User
LEFT JOIN 
    Badges b ON b.UserId = u.Id AND b.Date = (
        SELECT 
            MAX(Date) 
        FROM 
            Badges 
        WHERE 
            UserId = u.Id
    )  -- Latest Badge for User
WHERE 
    q.PostTypeId = 1  -- Only include Questions
GROUP BY 
    q.Id, q.Title, u.DisplayName, u.Reputation
HAVING 
    COUNT(DISTINCT a.Id) > 0 AND SUM(COALESCE(v.VoteCount, 0)) > 10  -- Only Questions with answers and more than 10 votes
ORDER BY 
    TotalVotes DESC, LatestBadgeDate DESC;

WITH RecentPostActivity AS (
    SELECT 
        PostId,
        COUNT(*) AS RecentVotes,
        RANK() OVER (PARTITION BY PostId ORDER BY CreationDate DESC) AS VoteRank
    FROM 
        Votes
    WHERE 
        CreationDate > NOW() - INTERVAL '30 days'  -- Only recent votes
    GROUP BY 
        PostId
)

SELECT 
    rph.PostId,
    rph.Title,
    rph.Level,
    COALESCE(rpa.RecentVotes, 0) AS RecentVotes,
    CASE 
        WHEN rph.Level = 0 THEN 'Root Question'
        ELSE 'Answer'
    END AS PostType
FROM 
    RecursivePostHierarchy rph
LEFT JOIN 
    RecentPostActivity rpa ON rph.PostId = rpa.PostId AND rpa.VoteRank = 1
ORDER BY 
    rph.Level, RecentVotes DESC;
