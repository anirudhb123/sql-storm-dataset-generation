WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        COALESCE(a.CommentCount, 0) AS CommentCount,
        COALESCE(a.ViewCount, 0) AS ViewCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        DENSE_RANK() OVER (ORDER BY COALESCE(a.Score, 0) DESC) AS RankByScore
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(*) AS AnswerCount,
            SUM(CommentCount) AS CommentCount,
            SUM(ViewCount) AS ViewCount,
            MAX(Score) AS Score
        FROM 
            Posts
        WHERE 
            PostTypeId = 2 -- Answers
        GROUP BY 
            ParentId
    ) a ON p.Id = a.ParentId
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Questions
), FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        CreationDate,
        AnswerCount,
        CommentCount,
        ViewCount,
        OwnerDisplayName,
        OwnerReputation,
        RankByScore
    FROM 
        RankedPosts
    WHERE 
        Tags LIKE '%SQL%' -- Filtering for posts tagged with SQL
)
SELECT 
    fp.Title,
    fp.OwnerDisplayName,
    fp.OwnerReputation,
    fp.AnswerCount,
    fp.CommentCount,
    fp.ViewCount,
    fp.CreationDate,
    STRING_AGG(DISTINCT bh.Name, ', ') AS BadgeNames,
    pp.LastEditDate,
    pp.LastEditorDisplayName,
    pp.Body
FROM 
    FilteredPosts fp
LEFT JOIN 
    Posts pp ON fp.PostId = pp.Id
LEFT JOIN 
    Badges b ON b.UserId = pp.OwnerUserId
LEFT JOIN 
    PostHistory ph ON ph.PostId = fp.PostId AND ph.PostHistoryTypeId IN (4, 5, 6) -- Title, Body, Tags edits
WHERE 
    fp.RankByScore <= 100 -- Limit to top 100 posts based on the rank by score
GROUP BY 
    fp.PostId, fp.Title, fp.OwnerDisplayName, fp.OwnerReputation, fp.AnswerCount, 
    fp.CommentCount, fp.ViewCount, fp.CreationDate, pp.LastEditDate, pp.LastEditorDisplayName, pp.Body
ORDER BY 
    fp.RankByScore;
