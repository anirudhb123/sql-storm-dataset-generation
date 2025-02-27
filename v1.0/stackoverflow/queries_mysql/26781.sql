
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
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
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
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1) AS TagName,
        COUNT(*) AS TagFrequency
    FROM 
        FilteredPosts
    INNER JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
        SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
        SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, ',', '')) >= numbers.n - 1
    GROUP BY 
        TagName
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
    TopTags tt ON f.Tags LIKE CONCAT('%', tt.TagName, '%')
WHERE 
    tt.FrequencyRank <= 5  
ORDER BY 
    f.CreationDate DESC, 
    tt.TagFrequency DESC;
