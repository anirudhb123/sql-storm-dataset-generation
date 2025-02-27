WITH RecursivePostHierarchy AS (
    -- Recursive CTE to get the hierarchy of questions and answers
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Starting with questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.PostId
)
SELECT 
    u.DisplayName, 
    u.Reputation,
    COUNT(DISTINCT p.Id) AS AnswerCount,
    SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveAnswers,
    AVG(v.BountyAmount) AS AverageBounty,
    MAX(b.Name) AS HighestBadge,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 2 -- Answers
LEFT JOIN 
    Votes v ON v.PostId = p.Id AND v.VoteTypeId = 8 -- Bounty Start
LEFT JOIN 
    Badges b ON b.UserId = u.Id
LEFT JOIN 
    Posts pt ON pt.Id = p.ParentId -- Joining with posts to get question data
LEFT JOIN 
    Tags t ON t.Id IN (SELECT UNNEST(STRING_TO_ARRAY(pt.Tags, ','))) -- Tags related to questions
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.Id
HAVING 
    COUNT(DISTINCT p.Id) > 5 -- Only considering users with more than 5 answers
ORDER BY 
    u.Reputation DESC,
    AnswerCount DESC
LIMIT 10;
This SQL query does the following:

1. It generates a recursive common table expression (CTE) to create a hierarchy of posts, capturing relationships between questions and their answers.

2. The main query aggregates data related to users:
   - Retrieves user display names and reputation.
   - Counts distinct answers.
   - Sums positive answer scores.
   - Calculates the average bounty amount associated with the user's answers.
   - Gets the highest badge the user holds.
   - Aggregates the unique tags used in their questions.

3. It filters users with a reputation greater than 1000 and answers more than 5 times.

4. Sorts the result based on reputation and answer count, and limits the output to the top 10 users.
