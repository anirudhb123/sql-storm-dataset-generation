
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.AcceptedAnswerId,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        DENSE_RANK() OVER (PARTITION BY value ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    CROSS APPLY (
        SELECT value FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><')
    ) AS SplitTags
    GROUP BY 
        p.Id, p.Title, p.Tags, u.DisplayName, p.CreationDate, p.AcceptedAnswerId, 
        p.AnswerCount, p.CommentCount, value
    HAVING 
        p.PostTypeId = 1
),
PopularTags AS (
    SELECT 
        value AS TagName, 
        COUNT(*) AS Frequency
    FROM 
        Posts
    CROSS APPLY (
        SELECT value FROM STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
    ) AS SplitTags
    WHERE 
        PostTypeId = 1
    GROUP BY 
        value
    ORDER BY 
        Frequency DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
)
SELECT 
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.AnswerCount,
    rp.CommentCount,
    pt.TagName,
    pt.Frequency
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON pt.TagName IN (SELECT value FROM STRING_SPLIT(SUBSTRING(rp.Tags, 2, LEN(rp.Tags) - 2), '><'))
WHERE 
    rp.TagRank <= 5
ORDER BY 
    pt.Frequency DESC, 
    rp.CreationDate DESC;
