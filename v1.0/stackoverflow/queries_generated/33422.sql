WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.AnswerCount,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Base case: Start with questions
    UNION ALL
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.AnswerCount,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ph.Level + 1 AS Level
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
)
SELECT 
    u.DisplayName,
    ph.Title AS QuestionTitle,
    ph.Score AS QuestionScore,
    COUNT(DISTINCT a.Id) AS AnswerCount,
    SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
    AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS AvgUpvotes,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    MAX(ph.CreationDate) AS MostRecentActivity,
    (SELECT COUNT(*) 
     FROM Comments c 
     WHERE c.PostId = ph.PostId) AS CommentCount,
    (SELECT STRING_AGG(DISTINCT history.Comment, '; ') 
     FROM PostHistory history 
     WHERE history.PostId = ph.PostId 
     AND history.PostHistoryTypeId IN (10, 11, 12) -- closed, reopened, deleted
    ) AS PostHistoryComments
FROM 
    PostHierarchy ph
LEFT JOIN 
    Posts a ON a.ParentId = ph.PostId -- Join to get answers
LEFT JOIN 
    Users u ON ph.OwnerUserId = u.Id -- Join to get user info
LEFT JOIN 
    Votes v ON v.PostId = ph.PostId -- Join to get vote info
LEFT JOIN 
    STRING_TO_ARRAY(substring(ph.Tags, 2, length(ph.Tags) - 2), '><') AS Tags ON TRUE -- Join tags
LEFT JOIN
    Tags t ON t.TagName = ANY(STRING_TO_ARRAY(substring(ph.Tags, 2, length(ph.Tags) - 2), '><'))
WHERE 
    ph.Level = 0 -- Only get top-level questions
GROUP BY 
    u.DisplayName, ph.Title, ph.Score
HAVING 
    COUNT(DISTINCT a.Id) > 0 AND  -- Ensure questions have answers
    AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) > 0 -- Have at least one upvote
ORDER BY 
    TotalBounty DESC, 
    QuestionScore DESC
LIMIT 100;
