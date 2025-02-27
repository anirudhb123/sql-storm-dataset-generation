WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1 -- Only interested in questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.AnswerCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5 -- Top 5 posts by view count for each tag
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.ViewCount,
    tp.CommentCount,
    tp.AnswerCount,
    STRING_AGG(t.TagName, ', ') AS RelatedTags
FROM 
    TopPosts tp
JOIN 
    LATERAL (
        SELECT 
            DISTINCT TRIM(UNNEST(string_to_array(tp.Tags, '>'))) AS TagName 
        FROM 
            Tags tg
        WHERE 
            tg.TagName = ANY(STRING_TO_ARRAY(tp.Tags, '>'))
    ) t ON TRUE
GROUP BY 
    tp.PostId, tp.Title, tp.OwnerDisplayName, tp.ViewCount, tp.CommentCount, tp.AnswerCount
ORDER BY 
    tp.ViewCount DESC;
