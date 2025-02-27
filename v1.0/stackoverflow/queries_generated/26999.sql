WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY t.TagName ORDER BY p.ViewCount DESC) AS RankByViewCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    CROSS JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        p.PostTypeId = 1 AND -- Only questions
        t.Count > 100 -- Tags with at least 100 usage
),
PostWithMostComments AS (
    SELECT 
        PostId, 
        Title, 
        Body, 
        ViewCount,
        AnswerCount,
        CommentCount,
        OwnerDisplayName,
        RANK() OVER (ORDER BY CommentCount DESC) AS CommentRank
    FROM 
        RankedPosts
),
TopThreeComments AS (
    SELECT 
        PostId, 
        Title, 
        Body, 
        ViewCount,
        AnswerCount,
        CommentCount,
        OwnerDisplayName
    FROM 
        PostWithMostComments
    WHERE 
        CommentRank <= 3
)
SELECT 
    t.TagName,
    pp.PostId,
    pp.Title,
    pp.Body,
    pp.ViewCount,
    pp.AnswerCount,
    pp.CommentCount,
    pp.OwnerDisplayName
FROM 
    Tags t
JOIN 
    TopThreeComments pp ON pp.Title LIKE '%' || t.TagName || '%'
ORDER BY 
    t.TagName, 
    pp.ViewCount DESC;
