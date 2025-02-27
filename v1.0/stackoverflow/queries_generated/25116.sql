WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        RANK() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownvoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
FilteredTags AS (
    SELECT 
        TRIM(UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><'))) ) AS TagName
    FROM 
        RankedPosts
),
TopTags AS (
    SELECT 
        TagName, 
        COUNT(*) AS TagCount 
    FROM 
        FilteredTags 
    GROUP BY 
        TagName 
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    p.Title,
    p.Body,
    p.OwnerDisplayName,
    p.CreationDate,
    p.Score,
    p.UpvoteCount,
    p.DownvoteCount,
    t.TagName
FROM 
    RankedPosts p
JOIN 
    TopTags t ON p.Tags LIKE '%' || t.TagName || '%'
WHERE 
    p.TagRank = 1 -- Only select the most recent post for each tag
ORDER BY 
    p.CreationDate DESC;
