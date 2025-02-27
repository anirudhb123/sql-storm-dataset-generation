WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS t(TagName)
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByScore <= 5  -- Get top 5 questions by score for each user
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate AS EditDate,
        ph.Comment,
        ph.Text,
        p.Title AS PostTitle
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  -- Edit Title, Edit Body, Edit Tags
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.Tags,
    ARRAY_AGG(ROW( phd.EditDate, phd.UserDisplayName, phd.Comment )) AS EditHistory
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistoryDetails phd ON tp.PostId = phd.PostId
GROUP BY 
    tp.PostId, tp.Title, tp.Body, tp.CreationDate, tp.ViewCount, tp.Score, tp.OwnerDisplayName, tp.CommentCount, tp.Tags
ORDER BY 
    tp.ViewCount DESC, tp.Score DESC;

This SQL query benchmarks string processing by targeting the `Posts` table and related comments and user data, producing a comprehensive analysis of the top questions and their edit history. It uses CTEs (Common Table Expressions) to break down the task into manageable pieces, aggregating relevant data and cleanly organizing it for output. The result includes details for the top five questions by score for each user, accumulating a history of edits made to each question. This query explores complex string aggregation and joins while giving insight into post activity and user engagement.
