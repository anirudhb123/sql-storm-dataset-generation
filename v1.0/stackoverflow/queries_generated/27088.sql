WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        u.DisplayName AS OwnerDisplayName,
        ARRAY_AGG(DISTINCT tg.TagName) AS TagsArray
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts ps ON ps.ParentId = p.Id
    LEFT JOIN 
        Tags tg ON tg.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, u.DisplayName
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.Score,
        rp.CreationDate,
        rp.ViewCount,
        rp.Rank,
        rp.OwnerDisplayName,
        rp.TagsArray
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1
),
PostAndComments AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Body,
        tp.Score,
        tp.ViewCount,
        tc.Text AS CommentText,
        tc.CreationDate AS CommentDate,
        u.DisplayName AS CommentUserName
    FROM 
        TopRankedPosts tp
    LEFT JOIN 
        Comments tc ON tc.PostId = tp.PostId
    LEFT JOIN 
        Users u ON tc.UserId = u.Id
)
SELECT 
    p.PostId,
    p.Title,
    p.Body,
    p.Score,
    p.ViewCount,
    COALESCE(COUNT(c.CommentText), 0) AS TotalComments,
    COALESCE(MAX(p.CommentDate), '1970-01-01'::timestamp) AS LastCommentDate,
    STRING_AGG(DISTINCT p.TagsArray, ', ') AS Tags,
    STRING_AGG(DISTINCT p.CommentText, ' | ') AS Comments,
    STRING_AGG(DISTINCT p.CommentUserName, ', ') AS CommentUsers
FROM 
    PostAndComments p
GROUP BY 
    p.PostId, p.Title, p.Body, p.Score, p.ViewCount
ORDER BY 
    p.Score DESC, p.ViewCount DESC;
