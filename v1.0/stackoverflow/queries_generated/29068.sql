WITH PostAnalytics AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(ph.Comment, 'No comments') AS LastEditComment,
        ph.CreationDate AS LastEditDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1  -- Questions only
),
FilteredPosts AS (
    SELECT 
        PostID,
        Title,
        Tags,
        CreationDate,
        ViewCount,
        AnswerCount,
        CommentCount,
        Score,
        OwnerDisplayName,
        LastEditComment,
        LastEditDate
    FROM 
        PostAnalytics
    WHERE 
        EditRank = 1  -- Most recent edit
        AND Score > 10  -- Only popular questions
        AND ViewCount > 100  -- Only questions with significant views
),
TagCount AS (
    SELECT 
        unnest(string_to_array(Tags, ',')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        FilteredPosts
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagCount
)
SELECT 
    fp.Title,
    fp.ViewCount,
    fp.AnswerCount,
    fp.CommentCount,
    fp.Score,
    fp.OwnerDisplayName,
    tt.Tag,
    tt.PostCount
FROM 
    FilteredPosts fp
JOIN 
    TopTags tt ON tt.Tag = ANY(string_to_array(fp.Tags, ','))
WHERE 
    tt.Rank <= 5  -- Get top 5 tags
ORDER BY 
    fp.ViewCount DESC, 
    fp.CreationDate DESC;
