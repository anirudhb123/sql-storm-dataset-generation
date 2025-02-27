
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.AnswerCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= CAST(DATEADD(year, -1, '2024-10-01') AS DATE)
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.OwnerUserId, u.DisplayName, p.AnswerCount
),
FrequentTags AS (
    SELECT 
        value AS Tag
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags)-2), '>') AS value
    WHERE 
        PostTypeId = 1
),
PopularTags AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        FrequentTags
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.AnswerCount,
    rp.CommentCount,
    pt.Tag AS PopularTag
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON rp.Title LIKE '%' + pt.Tag + '%'
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.CreationDate DESC, 
    rp.CommentCount DESC;
