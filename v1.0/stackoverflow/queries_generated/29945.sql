WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        RANK() OVER (ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
),
ProcessedPostTitles AS (
    SELECT 
        PostId,
        Title,
        UPPER(Title) AS UppercaseTitle,
        LOWER(Title) AS LowercaseTitle,
        LENGTH(Title) AS TitleLength,
        PostRank
    FROM 
        RankedPosts
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '>')::int[])
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(*) > 5  -- Consider tags used in more than 5 questions
)
SELECT 
    ppt.PostId,
    ppt.Title,
    ppt.UppercaseTitle,
    ppt.LowercaseTitle,
    ppt.TitleLength,
    ppt.PostRank,
    pt.TagName,
    pt.TagCount
FROM 
    ProcessedPostTitles ppt
JOIN 
    PopularTags pt ON ppt.PostId IN (SELECT PostId FROM Posts WHERE Tags LIKE '%' || pt.TagName || '%')
WHERE 
    ppt.PostRank <= 20  -- Fetch top 20 ranked posts
ORDER BY 
    ppt.PostRank, pt.TagCount DESC;
