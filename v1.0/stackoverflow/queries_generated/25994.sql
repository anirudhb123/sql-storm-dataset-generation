WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(u.Reputation) AS AverageReputation,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS TopUsers
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        AverageReputation,
        TopUsers,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagStats
)
SELECT 
    tt.TagName,
    tt.PostCount,
    tt.QuestionCount,
    tt.AnswerCount,
    tt.AverageReputation,
    tt.TopUsers,
    ph.UserDisplayName AS LastEditorUser,
    ph.CreationDate AS LastEditDate,
    ph.Comment AS EditComment
FROM 
    TopTags tt
LEFT JOIN (
    SELECT 
        p.Id,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5) -- Edit Title and Edit Body
) ph ON tt.TagName = ANY(STRING_TO_ARRAY((SELECT Tags FROM Posts WHERE Id = ph.PostId), ', '))
WHERE 
    tt.Rank <= 10
ORDER BY 
    tt.Rank;
