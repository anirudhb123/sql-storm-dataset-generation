WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
),
StringProcessedTags AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.UpvoteCount,
        rp.DownvoteCount,
        (SELECT STRING_AGG(tag.TagName, ', ') 
         FROM Tags tag 
         WHERE tag.Id IN (SELECT UNNEST(string_to_array(trim(both '<>' FROM rp.Tags), '><')::INT[]))) AS ProcessedTags
    FROM 
        RankedPosts rp
    WHERE 
        rn = 1 -- Only the latest version of each question
)
SELECT 
    PostId,
    Title,
    Body,
    CreationDate,
    Score,
    ViewCount,
    OwnerDisplayName,
    UpvoteCount,
    DownvoteCount,
    ProcessedTags
FROM 
    StringProcessedTags
ORDER BY 
    Score DESC, CreationDate DESC
LIMIT 10;
