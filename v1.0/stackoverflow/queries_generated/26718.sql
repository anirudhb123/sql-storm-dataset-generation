WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS Upvotes,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS Downvotes,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsUsed,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        unnest(string_to_array(p.Tags, '>')) AS tag ON tag IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        p.Id
),

StringProcessedPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Upvotes,
        Downvotes,
        TagsUsed,
        TRIM(BOTH ' ' FROM REPLACE(REPLACE(Title, ' ', ''), '-', '')) AS ProcessedTitle
    FROM 
        RankedPosts
    WHERE 
        rn = 1
)

SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    Upvotes,
    Downvotes,
    TagsUsed,
    ProcessedTitle,
    LENGTH(ProcessedTitle) AS ProcessedTitleLength
FROM 
    StringProcessedPosts
WHERE 
    LENGTH(ProcessedTitle) > 0
ORDER BY 
    ViewCount DESC
LIMIT 100;
