WITH PostTagCounts AS (
    -- Extracting and counting tags for each post
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Considering only questions
),
TagCounts AS (
    -- Grouping by tags to get their counts
    SELECT 
        Tag,
        COUNT(*) AS Count
    FROM 
        PostTagCounts
    GROUP BY 
        Tag
),
TopTags AS (
    -- Fetching the top 10 tags by count
    SELECT 
        Tag
    FROM 
        TagCounts
    ORDER BY 
        Count DESC
    LIMIT 10
),
PostDetails AS (
    -- Aggregating posts with relevant details on the top tags
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ARRAY_AGG(DISTINCT tt.Tag) AS Tags
    FROM 
        Posts p
    JOIN 
        PostTagCounts ptc ON p.Id = ptc.PostId
    JOIN 
        TopTags tt ON ptc.Tag = tt.Tag
    GROUP BY 
        p.Id
),
AuthorInfo AS (
    -- Joining with Users to get author details
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.Score,
        pd.ViewCount,
        pd.Tags,
        u.DisplayName AS AuthorDisplayName,
        u.Reputation AS AuthorReputation,
        COUNT(c.Id) AS CommentCount
    FROM 
        PostDetails pd
    LEFT JOIN 
        Users u ON pd.PostId = u.Id
    LEFT JOIN 
        Comments c ON pd.PostId = c.PostId
    GROUP BY 
        pd.PostId, u.DisplayName, u.Reputation
),
FinalResult AS (
    -- Formatting the final output with relevant metrics
    SELECT 
        AuthorDisplayName,
        AuthorReputation,
        Title,
        CreationDate,
        Score,
        ViewCount,
        Tags,
        CommentCount
    FROM 
        AuthorInfo
    ORDER BY 
        ViewCount DESC, Score DESC
)
SELECT * 
FROM FinalResult
LIMIT 20;
