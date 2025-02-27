
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
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            ParentId,
            AVG(Score) AS AvgAnswerScore
        FROM 
            Posts
        WHERE 
            PostTypeId = 2 
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
            GROUP_CONCAT(cr.Name) AS CloseReason
        FROM 
            PostHistory ph
        JOIN 
            CloseReasonTypes cr ON CAST(ph.Comment AS UNSIGNED) = cr.Id
        WHERE 
            ph.PostHistoryTypeId IN (10, 11) 
        GROUP BY 
            ph.PostId
    ) cl ON p.Id = cl.PostId
    LEFT JOIN (
        SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', numbers.n), '<', -1) AS TagName,
            p.Id
        FROM 
            Posts p
        JOIN 
            (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL 
             SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
        ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '>', '')) >= numbers.n - 1
    ) t ON p.Id = t.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.LastActivityDate, a.AvgAnswerScore, c.CommentCount, cl.CloseReason
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
    LENGTH(ps.Tags) > 0 
ORDER BY
    ps.LastActivityDate DESC,
    ps.AvgAnswerScore DESC;
