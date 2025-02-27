WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        U.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND p.Score > 0 -- Only questions with positive scores
),
TagStatistics AS (
    SELECT 
        TRIM(UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')))::text) AS TagName,
        COUNT(*) AS QuestionCount,
        SUM(CASE WHEN Score > 0 THEN 1 ELSE 0 END) AS UpvotedCount,
        SUM(CASE WHEN Score <= 0 THEN 1 ELSE 0 END) AS DownvotedCount
    FROM 
        Posts 
    WHERE 
        PostTypeId = 1 -- Only Questions
    GROUP BY 
        TagName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment,
        p.Title
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13) -- Only Close, Reopen, Delete, Undelete actions
)
SELECT 
    p.Rank,
    p.Title,
    p.OwnerDisplayName,
    p.CreationDate,
    t.TagName,
    ts.QuestionCount,
    ts.UpvotedCount,
    ts.DownvotedCount,
    ph.UserDisplayName AS HistoryUser,
    ph.CreationDate AS HistoryDate,
    ph.Comment AS HistoryComment
FROM 
    RankedPosts p
JOIN 
    TagStatistics ts ON ts.TagName = ANY (string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))
LEFT JOIN 
    PostHistoryDetails ph ON ph.PostId = p.PostId
WHERE 
    p.Rank <= 3 -- Top 3 posts per user
ORDER BY 
    p.CreationDate DESC;
