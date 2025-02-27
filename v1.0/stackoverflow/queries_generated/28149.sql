WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerName,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
),
HighScorers AS (
    SELECT 
        PostId, 
        Title, 
        OwnerName, 
        CreationDate,
        Score, 
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        PostRank = 1
        AND Score > 10 -- Only high-scoring posts
),
TagStatistics AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStatistics
)
SELECT 
    hs.Title,
    hs.OwnerName,
    hs.CreationDate,
    hs.Score,
    hs.CommentCount,
    tt.TagName,
    tt.PostCount
FROM 
    HighScorers hs
JOIN 
    Posts p ON hs.PostId = p.Id
JOIN 
    TopTags tt ON tt.TagName = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))
WHERE 
    tt.TagRank <= 5 -- Joining with top 5 tags based on post count
ORDER BY 
    hs.Score DESC, hs.CreationDate DESC;
