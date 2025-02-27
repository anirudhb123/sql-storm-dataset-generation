WITH RecursivePostHierarchy AS (
    SELECT 
        Id, 
        PostTypeId, 
        AcceptedAnswerId, 
        ParentId, 
        OwnerUserId, 
        Title, 
        CreationDate,
        0 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Starting with questions
    UNION ALL
    SELECT 
        p.Id, 
        p.PostTypeId, 
        p.AcceptedAnswerId, 
        p.ParentId, 
        p.OwnerUserId, 
        p.Title,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON rph.Id = p.ParentId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS QuestionsAsked,
    COUNT(DISTINCT a.Id) AS AnswersGiven,
    SUM(v.BountyAmount) AS TotalBountyReceived,
    COUNT(DISTINCT b.Id) AS TotalBadges,
    MAX(p.CreationDate) AS LastPostDate,
    AVG(DATEDIFF(MINUTE, p.CreationDate, GETDATE())) AS AvgMinutesSinceLastPost,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagNames,
    SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS TotalPostsClosed
FROM 
    Users u
LEFT JOIN 
    Posts p ON p.OwnerUserId = u.Id AND p.PostTypeId = 1 -- Questions
LEFT JOIN 
    Posts a ON a.ParentId = p.Id -- Answers to questions
LEFT JOIN 
    Votes v ON v.UserId = u.Id AND v.VoteTypeId IN (8, 9) -- Bounty votes
LEFT JOIN 
    Badges b ON b.UserId = u.Id
LEFT JOIN 
    Tags t ON t.Id IN (SELECT id FROM STRING_SPLIT(p.Tags, ',')) -- Assuming a function splits tags
LEFT JOIN 
    PostHistory ph ON ph.PostId = p.Id
WHERE 
    u.Reputation > 1000 -- Only consider users with more than 1000 reputation
GROUP BY 
    u.Id, u.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) > 10 -- Only users who have asked more than 10 questions
ORDER BY 
    TotalBountyReceived DESC, QuestionsAsked DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY; -- Pagination for top 10 Users
