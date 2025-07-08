
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        RANK() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotes
    FROM 
        Posts p
        JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
        JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, u.Id, u.DisplayName, p.Title, p.Body, p.Tags, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        OwnerDisplayName,
        CreationDate,
        CommentCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        PostRank = 1  
),
TagCounts AS (
    SELECT 
        TRIM(value) AS TagName,
        COUNT(*) AS TagFrequency
    FROM 
        FilteredPosts,
        LATERAL FLATTEN(input => SPLIT(Tags, ',')) AS tag
    GROUP BY 
        TRIM(value)
),
TopTags AS (
    SELECT 
        TagName,
        TagFrequency,
        RANK() OVER (ORDER BY TagFrequency DESC) AS FrequencyRank
    FROM 
        TagCounts
)
SELECT 
    f.OwnerDisplayName,
    f.Title,
    f.CreationDate,
    f.CommentCount,
    f.UpVotes,
    f.DownVotes,
    tt.TagName,
    tt.TagFrequency
FROM 
    FilteredPosts f
JOIN 
    TopTags tt ON f.Tags LIKE '%' || tt.TagName || '%'
WHERE 
    tt.FrequencyRank <= 5  
ORDER BY 
    f.CreationDate DESC, 
    tt.TagFrequency DESC;
