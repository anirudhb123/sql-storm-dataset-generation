WITH RecursivePostHistory AS (
    -- CTE to track the hierarchy of posts, especially where questions have answers.
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        CAST(NULL AS varchar(8000)) AS ParentTitle,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions only
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        ph.Title AS ParentTitle,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHistory ph ON p.ParentId = ph.PostId
)
SELECT 
    u.DisplayName AS UserName,
    COUNT(DISTINCT p.Id) AS QuestionCount,
    SUM(CASE WHEN p.Score >= 0 THEN 1 ELSE 0 END) AS PositiveQuestions,
    SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeQuestions,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed,
    MAX(p.CreationDate) AS LastQuestionDate,
    COALESCE(NULLIF(SUM(b.Class = 1), 0), 0) AS GoldBadges,
    COALESCE(NULLIF(SUM(b.Class = 2), 0), 0) AS SilverBadges,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 -- Questions only
LEFT JOIN 
    Tags t ON t.WikiPostId = p.Id -- Example of joining on a tag's wiki post
LEFT JOIN 
    Badges b ON b.UserId = u.Id
LEFT JOIN 
    Votes v ON v.PostId = p.Id
GROUP BY 
    u.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) > 10 -- More than 10 questions
ORDER BY 
    LastQuestionDate DESC;

This SQL query does the following:
1. Defines a recursive Common Table Expression (CTE) to gather questions and their direct answers hierarchically.
2. Gathers user statistics such as question count, positive and negative questions, tags used, and badges earned.
3. Uses `STRING_AGG` to concatenate tags associated with the questions.
4. Counts the types of votes received (upvotes and downvotes).
5. Filters results to only include users who have asked more than ten questions, ordered by the most recent question date.
