WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        ARRAY_LENGTH(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'), 1) AS TagCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    rp.TagCount,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVoteCount -- Upvotes only
FROM 
    RankedPosts rp
WHERE 
    rp.rn <= 5 -- Top 5 recent questions per user 
ORDER BY 
    rp.OwnerUserId, rp.CreationDate DESC;

-- Post-processing: Dynamic String Aggregation for Tag Lists
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(tag.TagName, ', ') AS TagList
    FROM 
        Posts p
    JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS t(tag) ON p.Id IS NOT NULL
    GROUP BY 
        p.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    rp.TagCount,
    pt.TagList,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVoteCount -- Upvotes only
FROM 
    RankedPosts rp
JOIN 
    PostTags pt ON rp.PostId = pt.PostId
WHERE 
    rp.rn <= 5 -- Top 5 recent questions per user 
ORDER BY 
    rp.OwnerUserId, rp.CreationDate DESC;
