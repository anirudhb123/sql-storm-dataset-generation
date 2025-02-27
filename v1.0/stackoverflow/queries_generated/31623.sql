WITH RecursivePostHierarchy AS (
    -- Get all answers with their associated questions using a recursive CTE
    SELECT 
        p.Id AS PostId,
        p.Title AS PostTitle,
        p.PostTypeId,
        p.ParentId,
        p.CreationDate,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions
    UNION ALL
    SELECT 
        p2.Id,
        p2.Title,
        p2.PostTypeId,
        p2.ParentId,
        p2.CreationDate,
        Level + 1
    FROM 
        Posts p2
    INNER JOIN RecursivePostHierarchy rph ON p2.ParentId = rph.PostId
)

-- Select from the recursive CTE with additional metrics
SELECT 
    rp.PostId,
    rp.PostTitle,
    rp.Level,
    COUNT(a.Id) AS AnswerCount,
    COALESCE(SUM(v.VoteTypeId = 2), 0) AS Upvotes,
    COALESCE(SUM(v.VoteTypeId = 3), 0) AS Downvotes,
    AVG(CASE 
            WHEN c.UserId IS NOT NULL THEN c.Score  -- Average score of comments per post
            ELSE 0 
        END) AS AvgCommentScore,
    p.CreationDate AS QuestionCreationDate,
    STRING_AGG(t.TagName, ', ') AS Tags,
    DENSE_RANK() OVER (ORDER BY p.CreationDate DESC) AS QuestionRank
FROM 
    RecursivePostHierarchy rp
LEFT JOIN 
    Posts p ON rp.PostId = p.Id 
LEFT JOIN 
    Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2  -- Answers
LEFT JOIN 
    Votes v ON a.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Tags t ON t.ExcerptPostId = p.Id
GROUP BY 
    rp.PostId,
    rp.PostTitle,
    rp.Level,
    p.CreationDate
HAVING 
    COUNT(a.Id) > 0  -- Only include questions with answers
ORDER BY 
    QuestionRank;

-- Further analysis to identify posts with extreme engagement 
SELECT 
    rp.PostId,
    rp.PostTitle,
    COUNT(DISTINCT a.Id) AS TotalAnswers,
    COUNT(DISTINCT c.Id) AS TotalComments,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
    SUM(CASE WHEN bp.UserId IS NOT NULL THEN 1 ELSE 0 END) AS BacklinkCount
FROM 
    RecursivePostHierarchy rp
LEFT JOIN 
    Posts a ON rp.PostId = a.ParentId AND a.PostTypeId = 2
LEFT JOIN 
    Comments c ON a.Id = c.PostId
LEFT JOIN 
    Votes v ON a.Id = v.PostId
LEFT JOIN 
    PostLinks pl ON pl.PostId = rp.PostId
LEFT JOIN 
    Posts bp ON pl.RelatedPostId = bp.Id
GROUP BY 
    rp.PostId,
    rp.PostTitle
HAVING 
    SUM(v.VoteTypeId = 2) > 50  -- High engagement posts
ORDER BY 
    TotalAnswers DESC;
