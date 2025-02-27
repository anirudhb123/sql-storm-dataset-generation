WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND  -- Only considering questions
        p.CreationDate >= '2023-01-01'  -- Questions created this year
),
TopTaggedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.Tags,
        STRING_AGG(t.TagName, ', ') AS TagList
    FROM 
        RankedPosts rp
    JOIN 
        STRING_TO_ARRAY(rp.Tags, '><') AS tag_splits ON TRUE  -- Split tags into rows for aggregation
    JOIN 
        Tags t ON t.TagName = TRIM(BOTH '<>' FROM tag_splits)
    WHERE 
        rp.Rank <= 10  -- Top 10 posts by score
    GROUP BY 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, ' | ') AS Comments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostStats AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Score,
        tp.ViewCount,
        tp.TagList,
        COALESCE(pc.CommentCount, 0) AS TotalComments,
        COALESCE(pc.Comments, 'No comments') AS CommentsSnippet
    FROM 
        TopTaggedPosts tp
    LEFT JOIN 
        PostComments pc ON tp.PostId = pc.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.TagList,
    ps.TotalComments,
    ps.CommentsSnippet,
    COALESCE(u.DisplayName, 'Anonymous') AS AuthorDisplayName,
    COUNT(v.Id) AS TotalVotes,
    MAX(b.Date) AS LastBadgeDate
FROM 
    PostStats ps
LEFT JOIN 
    Posts post ON ps.PostId = post.Id
LEFT JOIN 
    Users u ON post.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON post.Id = v.PostId -- Join on votes to get vote counts
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    ps.TotalComments > 0 -- Filter only posts with comments
GROUP BY 
    ps.PostId, ps.Title, ps.Score, ps.ViewCount, ps.TagList, ps.TotalComments, ps.CommentsSnippet, u.DisplayName
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC -- Order by score and view count
LIMIT 50; -- Limit the result set to 50
