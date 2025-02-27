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
        ARRAY_AGG(DISTINCT SUBSTRING(t.TagName FROM 1 FOR 35)) AS Tags,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostsTags pt ON p.Id = pt.PostId
    LEFT JOIN 
        Tags t ON pt.TagId = t.Id
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id, u.DisplayName
),

TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        ViewCount,
        Score,
        OwnerDisplayName,
        CommentCount,
        Tags,
        AnswerCount
    FROM 
        RankedPosts
    WHERE 
        OwnerPostRank <= 5 -- Only select the top 5 posts per user
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
    STRING_AGG(tag, ', ') AS FormattedTags,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes
FROM 
    TopPosts tp
LEFT JOIN 
    Votes v ON tp.PostId = v.PostId
GROUP BY 
    tp.PostId, tp.Title, tp.Body, tp.CreationDate, tp.ViewCount, tp.Score, tp.OwnerDisplayName, tp.CommentCount
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC
LIMIT 100; -- Limit the results to the top 100 posts based on score and view count
