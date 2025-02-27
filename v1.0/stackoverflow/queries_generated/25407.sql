WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COALESCE(ROUND(CAST(SUM(v.VoteTypeId = 2) AS FLOAT) / NULLIF(SUM(v.VoteTypeId IN (2, 3)), 0) * 100, 2), 0) AS UpvotePercentage,
        RANK() OVER (ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND (p.LastActivityDate >= NOW() - INTERVAL '1 year') -- Only questions from the last year
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Body, p.Tags, u.DisplayName, p.ViewCount
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        OwnerDisplayName,
        ViewCount,
        AnswerCount,
        UpvotePercentage
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 10
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.ViewCount,
    tp.AnswerCount,
    tp.UpvotePercentage,
    COALESCE(t.TagName, 'No Tags') AS TagName,
    CASE 
        WHEN tp.UpvotePercentage > 70 THEN 'Hot'
        WHEN tp.UpvotePercentage >= 50 THEN 'Popular'
        ELSE 'Regular'
    END AS PopularityCategory
FROM 
    TopPosts tp
LEFT JOIN 
    Tags t ON POSITION(CONCAT('>', t.TagName, '<') IN CONCAT('>', tp.Tags, '<')) > 0
ORDER BY 
    tp.ViewCount DESC;
