WITH TagFrequency AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        COUNT(DISTINCT Id) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Only questions
    GROUP BY 
        TagName
),
TagStats AS (
    SELECT 
        t.TagName,
        tf.PostCount,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        AVG(p.Score) AS AvgScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        TagFrequency tf
    JOIN 
        Tags t ON t.TagName = tf.TagName
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        t.Count > 50  -- Consider tags with more than 50 occurrences
    GROUP BY 
        t.TagName, tf.PostCount
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStats
    WHERE 
        PostCount > 5  -- Only tags that appeared in more than 5 posts
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        t.TagName,
        CASE 
            WHEN ph.Comment IS NOT NULL THEN ph.Comment 
            ELSE 'No comments' 
        END AS LastEditComment,
        ph.CreationDate AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5)  -- Edit Title and Body
    JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        p.PostTypeId = 1  -- Only questions
)
SELECT 
    tt.TagName,
    tt.PostCount,
    COUNT(DISTINCT pd.PostId) AS CountOfQuestions,
    SUM(pd.Score) AS TotalScore,
    SUM(pd.ViewCount) AS TotalViews,
    AVG(pd.Score) AS AvgQuestionScore,
    AVG(EXTRACT(EPOCH FROM NOW() - pd.CreationDate)) / 86400 AS AvgDaysSinceCreation
FROM 
    TopTags tt
JOIN 
    PostDetails pd ON pd.TagName = tt.TagName
GROUP BY 
    tt.TagName, tt.PostCount
ORDER BY 
    tt.TagRank;
