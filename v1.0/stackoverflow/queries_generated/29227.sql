WITH PostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        COALESCE(a.AvgAnswerScore, 0) AS AvgAnswerScore,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(cl.CloseReason, 'Not Closed') AS CloseReason,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            ParentId,
            AVG(Score) AS AvgAnswerScore
        FROM 
            Posts
        WHERE 
            PostTypeId = 2 -- Answer
        GROUP BY 
            ParentId
    ) a ON p.Id = a.ParentId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(Id) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            ph.PostId, 
            STRING_AGG(cr.Name, ', ') AS CloseReason
        FROM 
            PostHistory ph
        JOIN 
            CloseReasonTypes cr ON ph.Comment::int = cr.Id
        WHERE 
            ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
        GROUP BY 
            ph.PostId
    ) cl ON p.Id = cl.PostId
    LEFT JOIN (
        SELECT 
            unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '>')) AS TagName,
            p.Id
        FROM 
            Posts p
    ) t ON p.Id = t.Id
    WHERE 
        p.PostTypeId = 1 -- Questions
    GROUP BY 
        p.Id, a.AvgAnswerScore, c.CommentCount, cl.CloseReason
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.LastActivityDate,
    ps.AvgAnswerScore,
    ps.CommentCount,
    ps.CloseReason,
    ps.Tags,
    CASE 
        WHEN ps.AvgAnswerScore > 10 THEN 'High Engagement'
        WHEN ps.CommentCount > 5 THEN 'Discussion Active'
        WHEN ps.CloseReason <> 'Not Closed' THEN 'Marked for Closure'
        ELSE 'Standard Question'
    END AS EngagementCategory
FROM
    PostStats ps
WHERE
    ARRAY_LENGTH(ps.Tags, 1) > 0 -- Only posts with tags
ORDER BY
    ps.LastActivityDate DESC,
    ps.AvgAnswerScore DESC;
