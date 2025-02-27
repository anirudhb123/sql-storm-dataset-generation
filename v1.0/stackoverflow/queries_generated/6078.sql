WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        RANK() OVER (ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        UNNEST(string_to_array(p.Tags, '>')) AS t(TagName) ON TRUE
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.AnswerCount,
        rp.Tags,
        rp.RankScore
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankScore <= 10 -- Top 10 scored posts
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserDisplayName AS Editor,
        ph.CreationDate AS EditDate,
        ph.Comment
    FROM 
        PostHistory ph
    JOIN 
        FilteredPosts fp ON ph.PostId = fp.PostId
    ORDER BY 
        ph.CreationDate DESC
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Score,
    fp.OwnerDisplayName,
    fp.CommentCount,
    fp.AnswerCount,
    string_agg(DISTINCT fp.Tags, ', ') AS CombinedTags,
    jsonb_agg(jsonb_build_object('Editor', phd.Editor, 'EditType', pt.Name, 'EditDate', phd.EditDate, 'Comment', phd.Comment)) AS EditHistory
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostHistoryDetails phd ON fp.PostId = phd.PostId
LEFT JOIN 
    PostHistoryTypes pt ON phd.PostHistoryTypeId = pt.Id
GROUP BY 
    fp.PostId, fp.Title, fp.Score, fp.OwnerDisplayName, fp.CommentCount, fp.AnswerCount
ORDER BY 
    fp.Score DESC;
