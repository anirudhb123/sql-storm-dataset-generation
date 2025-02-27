WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        t.TagName,
        u.DisplayName AS AuthorName,
        RANK() OVER (PARTITION BY t.TagName ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        Tags t ON t.Id IN (SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'))::int)
                           WHERE t.TagName IS NOT NULL)
    WHERE 
        p.PostTypeId = 1 -- Questions only
),

TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        CommentCount,
        TagName,
        AuthorName
    FROM 
        RankedPosts
    WHERE 
        ScoreRank <= 5 -- Top 5 posts per tag
),

PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate AS EditDate,
        ph.Comment,
        ph.Text AS NewValue,
        p.Title AS PostTitle
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Title, Body, Tags edits
)

SELECT 
    r.PostId,
    r.Title,
    r.Body,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    r.AnswerCount,
    r.CommentCount,
    r.TagName,
    r.AuthorName,
    COALESCE(ARRAY_AGG(DISTINCT ph.UserDisplayName) FILTER (WHERE ph.EditDate IS NOT NULL), '{}') AS Editors,
    COALESCE(ARRAY_AGG(DISTINCT ph.NewValue) FILTER (WHERE ph.EditDate IS NOT NULL), '{}') AS EditedValues,
    COUNT(DISTINCT ph.EditDate) AS EditCount
FROM 
    TopRankedPosts r
LEFT JOIN 
    PostHistoryDetails ph ON r.PostId = ph.PostId
GROUP BY 
    r.PostId, r.Title, r.Body, r.CreationDate, r.Score, r.ViewCount, r.AnswerCount, r.CommentCount, r.TagName, r.AuthorName
ORDER BY 
    r.CreationDate DESC
LIMIT 100;
