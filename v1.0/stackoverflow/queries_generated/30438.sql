WITH RecursivePostCTE AS (
    SELECT 
        Id, 
        Title,
        Score,
        OwnerUserId,
        CreationDate,
        AcceptedAnswerId,
        0 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only questions

    UNION ALL

    SELECT 
        p.Id, 
        p.Title,
        p.Score,
        p.OwnerUserId,
        p.CreationDate,
        p.AcceptedAnswerId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE r ON p.ParentId = r.Id -- Join to find answers to each question
)

SELECT 
    q.Id AS QuestionId,
    q.Title AS QuestionTitle,
    q.Score AS QuestionScore,
    u.DisplayName AS OwnerName,
    u.Reputation AS OwnerReputation,
    COUNT(DISTINCT a.Id) AS AnswerCount,
    MAX(a.Score) AS TopAnswerScore, -- Highest score of the answers
    MIN(COALESCE(c.Score, 0)) AS MinAnswerScore, -- Minimum score while considering NULL
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount, -- Count of UpVotes
    COUNT(DISTINCT b.Id) AS BadgeCount -- Count of associated badges for the user
FROM 
    RecursivePostCTE q
LEFT JOIN 
    Posts a ON q.Id = a.ParentId -- Join to get the answers
LEFT JOIN 
    Users u ON q.OwnerUserId = u.Id -- Join to get the owner's info
LEFT JOIN 
    Votes v ON a.Id = v.PostId -- Join to get votes on answers
LEFT JOIN 
    Badges b ON u.Id = b.UserId -- Join to get badges for the user
GROUP BY 
    q.Id, q.Title, q.Score, u.DisplayName, u.Reputation
HAVING 
    COUNT(DISTINCT a.Id) > 0 -- Consider only questions that have answers
ORDER BY 
    QuestionScore DESC, QuestionId ASC; -- Order by question score and then id
