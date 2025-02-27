WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        COALESCE(p.Score, 0) AS Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 -- Considering only questions
        AND p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year' -- Filter for the last year
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        CreationDate,
        OwnerDisplayName,
        AnswerCount,
        Score
    FROM 
        RankedPosts
    WHERE 
        TagRank <= 5 -- Top 5 most recent in each tag category
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.AnswerCount,
    tp.Score,
    STRING_AGG(UNIQUE(UPPER(t.TagName)), ', ') AS UniqueTags -- Aggregating unique tags, uppercase
FROM 
    TopPosts tp
LEFT JOIN 
    LATERAL (
        SELECT 
            unnest(string_to_array(tp.Tags, '><')) AS TagName
    ) t ON TRUE
GROUP BY 
    tp.Title, tp.OwnerDisplayName, tp.AnswerCount, tp.Score
ORDER BY 
    tp.Score DESC, tp.AnswerCount DESC;
