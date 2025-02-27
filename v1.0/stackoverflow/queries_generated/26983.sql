WITH ProcessedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagsList
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE 
        p.PostTypeId IN (1, 2) -- Only include questions and answers
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.OwnerName,
    pp.CreationDate,
    pp.CommentCount,
    pp.BadgeCount,
    pp.TagsList,
    phs.HistoryCount,
    phs.HistoryTypes
FROM 
    ProcessedPosts pp
LEFT JOIN 
    PostHistorySummary phs ON pp.PostId = phs.PostId
ORDER BY 
    pp.CommentCount DESC, pp.BadgeCount DESC, pp.CreationDate DESC
LIMIT 100;
This query does the following:
1. It creates a Common Table Expression (CTE) `ProcessedPosts`, which aggregates data from the `Posts`, `Users`, `Comments`, `Badges`, and `Tags` tables to provide a summary of post information, including the total number of comments, badges received by the post owner, and a concatenated list of tags associated with each post.

2. It creates another CTE `PostHistorySummary`, which aggregates the post history for each post, counting the number of history records and listing the types of changes that have occurred.

3. Finally, it selects relevant fields from both CTEs, joining them on the post ID, and orders the results by comment count, badge count, and post creation date to ensure the most engaging posts are shown first, limited to 100 results. This structure enables efficient string processing benchmarking by providing complex string aggregations and associations across multiple tables.
