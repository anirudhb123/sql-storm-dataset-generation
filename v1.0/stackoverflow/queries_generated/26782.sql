WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
RecentClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        ph.Text AS ReasonText
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Posts that were closed
        AND ph.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '30 days') -- Last 30 days
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.AnswerCount) AS TotalAnswers,
        SUM(p.CommentCount) AS TotalComments
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[]) -- Splitting Tags
    GROUP BY 
        t.TagName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.CreationDate,
    rp.Score,
    rp.AnswerCount,
    rp.CommentCount,
    rp.OwnerDisplayName,
    rcp.CreationDate AS ClosedDate,
    rcp.UserDisplayName AS ClosedBy,
    rcp.Comment AS ClosedComment,
    rcp.ReasonText,
    ts.PostCount,
    ts.TotalAnswers,
    ts.TotalComments
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentClosedPosts rcp ON rp.PostId = rcp.PostId
LEFT JOIN 
    TagStatistics ts ON rp.Tags LIKE '%' || ts.TagName || '%' -- Getting statistics for tags
WHERE 
    rp.rn = 1 -- Get most recent post for each tag
ORDER BY 
    rp.CreationDate DESC;

This SQL query performs the following tasks:
1. **RankedPosts CTE**: Ranks the questions based on their creation date for each tag.
2. **RecentClosedPosts CTE**: Fetches posts that were closed in the last 30 days along with the reason for closure.
3. **TagStatistics CTE**: Aggregates statistics about the posts associated with each tag — count of posts, total answers, and total comments.
4. **Final SELECT**: Joins all these CTEs to produce a comprehensive view of the most recent question for each tag, including details if it has been closed recently, along with statistics about tags.
