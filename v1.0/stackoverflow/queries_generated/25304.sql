WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(p.Tags, '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
PostsWithTags AS (
    SELECT 
        rp.PostId, 
        rp.Title,
        rp.Body,
        rp.Author,
        rp.CommentCount,
        rp.AnswerCount,
        pt.TagName
    FROM 
        RankedPosts rp
    JOIN 
        PopularTags pt ON rp.Tags LIKE CONCAT('%<', pt.TagName, '>%')
)
SELECT 
    PostId,
    Title,
    Body,
    Author,
    CommentCount,
    AnswerCount,
    STRING_AGG(TagName, ', ') AS RelatedTags    
FROM 
    PostsWithTags
GROUP BY 
    PostId, Title, Body, Author, CommentCount, AnswerCount
ORDER BY 
    AnswerCount DESC, CommentCount DESC;
