WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        STRING_AGG(DISTINCT CONCAT(u.DisplayName, ': ', c.Text), ' | ') AS Comments,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2 -- Answers
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Users u ON c.UserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.AnswerCount,
        rp.Comments
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 10
),
PostTags AS (
    SELECT 
        pt.TagName,
        COUNT(pt.PostId) AS TagUsageCount
    FROM 
        Tags pt
    JOIN 
        Posts p ON ',' || p.Tags || ',' LIKE '%,' || pt.TagName || ',%' 
    GROUP BY 
        pt.TagName
    ORDER BY 
        TagUsageCount DESC
    LIMIT 5
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.AnswerCount,
    tp.Comments,
    STRING_AGG(pt.TagName, ', ') AS PopularTags
FROM 
    TopPosts tp
JOIN 
    PostTags pt ON tp.Tags LIKE '%' || pt.TagName || '%'
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.AnswerCount, tp.Comments
ORDER BY 
    tp.CreationDate DESC;
