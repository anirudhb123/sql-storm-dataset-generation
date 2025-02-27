WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(COALESCE(p.Score, 0)) AS AverageScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName, 
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagStats
    WHERE 
        PostCount > 0 
)
SELECT 
    tt.TagName,
    tt.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.AverageScore,
    ts.TotalViews,
    COALESCE(pht.EditCount, 0) AS TotalEdits,
    COALESCE(cmt.CommentCount, 0) AS TotalComments
FROM 
    TopTags tt
JOIN 
    TagStats ts ON tt.TagName = ts.TagName
LEFT JOIN (
    SELECT 
        t.TagName, 
        COUNT(ph.Id) AS EditCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    JOIN 
        PostHistory ph ON ph.PostId = p.Id AND ph.PostHistoryTypeId IN (4, 5)  -- Title and Body edits
    GROUP BY 
        t.TagName
) pht ON tt.TagName = pht.TagName
LEFT JOIN (
    SELECT 
        t.TagName,
        COUNT(c.Id) AS CommentCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    GROUP BY 
        t.TagName
) cmt ON tt.TagName = cmt.TagName
WHERE 
    tt.Rank <= 10  -- Top 10 tags by number of posts
ORDER BY 
    tt.Rank;
