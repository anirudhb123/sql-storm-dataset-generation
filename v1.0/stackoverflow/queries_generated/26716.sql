WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= DATEADD(year, -1, GETDATE()) -- Last year
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.OwnerReputation
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank = 1 -- Top post in each tag
),
PostWithComments AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Body,
        tp.Tags,
        tp.Score,
        tp.ViewCount,
        tp.OwnerDisplayName,
        tp.OwnerReputation,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, ' | ') AS CommentTexts -- Concatenating all comments
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.Body, tp.Tags, tp.Score, tp.ViewCount, tp.OwnerDisplayName, tp.OwnerReputation
)
SELECT 
    pwc.PostId,
    pwc.Title,
    pwc.Body,
    pwc.Tags,
    pwc.Score,
    pwc.ViewCount,
    pwc.OwnerDisplayName,
    pwc.OwnerReputation,
    pwc.CommentCount,
    pwc.CommentTexts,
    ISNULL(t.Count, 0) AS TagPopularity, -- Popularity by usage count from Tags table
    pht.Name AS PostHistoryType
FROM 
    PostWithComments pwc
LEFT JOIN 
    Tags t ON pwc.Tags LIKE '%' + t.TagName + '%'
LEFT JOIN 
    PostHistory ph ON pwc.PostId = ph.PostId
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE 
    pwc.Score > 0 -- Only considering posts with a positive score
ORDER BY 
    pwc.Score DESC, 
    pwc.ViewCount DESC;
