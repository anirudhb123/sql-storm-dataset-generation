WITH RecursivePostHierarchy AS (
    -- Recursive CTE to find all answers for questions
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate AS PostCreationDate,
        p.AcceptedAnswerId,
        1 as Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions
    UNION ALL
    SELECT 
        a.Id,
        a.Title,
        a.OwnerUserId,
        a.CreationDate,
        a.AcceptedAnswerId,
        Level + 1
    FROM 
        Posts a
    JOIN 
        RecursivePostHierarchy rph ON a.ParentId = rph.PostId
    WHERE 
        a.PostTypeId = 2 -- Answers
),
UserReputation AS (
    -- Subquery to calculate reputation and total contributions for each user
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    -- CTE to find top users by contributions
    SELECT 
        ur.DisplayName,
        (ur.Reputation + COALESCE(ur.TotalPosts, 0) * 10 + COALESCE(ur.TotalComments, 0) * 5 + COALESCE(ur.TotalBounty, 0)) AS ContributionScore
    FROM 
        UserReputation ur
    ORDER BY 
        ContributionScore DESC
    LIMIT 10 -- Top 10 Users
)
SELECT
    p.Title AS QuestionTitle,
    u.DisplayName AS UserDisplayName,
    ur.Reputation AS UserReputation,
    COUNT(a.Id) AS TotalAnswers,
    SUM(CASE WHEN a.Id IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS AnswerCount,
    SUM(CASE WHEN ph.Comment IS NOT NULL THEN 1 ELSE 0 END) AS TotalCommentsOnAnswers,
    DATEDIFF(NOW(), p.CreationDate) AS DaysSincePosted,
    CASE
        WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
        ELSE 'Not Accepted'
    END AS AnswerStatus,
    STRING_AGG(DISTINCT t.TagName, ', ') AS RelatedTags
FROM 
    Posts p
JOIN 
    RecursivePostHierarchy rph ON p.Id = rph.PostId
LEFT JOIN 
    Posts a ON a.ParentId = p.Id -- Answers
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON a.Id = c.PostId
LEFT JOIN 
    Tags t ON POSITION(t.TagName IN p.Tags) > 0 -- Check if Tag is in Tags column
LEFT JOIN 
    PostHistory ph ON ph.PostId = p.Id -- For additional history
WHERE 
    p.PostTypeId = 1 -- Questions
GROUP BY 
    p.Title, u.DisplayName, ur.Reputation, p.Id
ORDER BY 
    TotalAnswers DESC, DaysSincePosted; -- Most answered questions first
