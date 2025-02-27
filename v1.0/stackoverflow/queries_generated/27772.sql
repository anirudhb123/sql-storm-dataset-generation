WITH StringProcessing AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment,
        ph.Text
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Filtering to include edits (title, body, tags)
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- Last year's posts
),
TagAnalysis AS (
    SELECT 
        unnest(string_to_array(Tags, '><')) AS Tag,
        COUNT(*) AS UsageCount
    FROM 
        StringProcessing
    GROUP BY 
        Tag
),
RecentComments AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    WHERE 
        CreationDate >= CURRENT_DATE - INTERVAL '1 month' -- Last month's comments
    GROUP BY 
        PostId
),
Engagement AS (
    SELECT 
        sp.PostId,
        sp.Title,
        sp.Body,
        sp.Tags,
        COALESCE(rc.CommentCount, 0) AS CommentCount,
        ta.UsageCount AS TagUsageCount
    FROM 
        StringProcessing sp
    LEFT JOIN 
        RecentComments rc ON sp.PostId = rc.PostId
    LEFT JOIN 
        TagAnalysis ta ON ta.Tag = ANY(string_to_array(sp.Tags, '><'))
),
Ranking AS (
    SELECT 
        *,
        (CommentCount * 0.6 + TagUsageCount * 0.4) AS EngagementScore
    FROM 
        Engagement
)
SELECT 
    PostId,
    Title,
    Body,
    Tags,
    CommentCount,
    TagUsageCount,
    EngagementScore
FROM 
    Ranking
ORDER BY 
    EngagementScore DESC
LIMIT 10; -- Top 10 posts based on engagement score
This SQL query is designed to benchmark string processing related to posts from the Stack Overflow schema. It analyzes edited posts over the past year, extracts tags and their usage, counts comments from the last month, and combines these metrics into an engagement score to identify the top 10 posts.
