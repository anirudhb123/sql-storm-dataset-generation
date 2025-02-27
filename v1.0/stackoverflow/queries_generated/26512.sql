WITH TagCounts AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCreated,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCreated
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id, u.Reputation
),
RecentEdits AS (
    SELECT 
        ph.UserId,
        COUNT(ph.Id) AS EditCount,
        AVG(DATE_PART('epoch', NOW() - ph.CreationDate)) AS AvgTimeSinceEdit
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  -- Title, Body, Tags edits
    GROUP BY 
        ph.UserId
)

SELECT 
    tc.TagName,
    tc.PostCount,
    tc.QuestionCount,
    tc.AnswerCount,
    ur.UserId,
    ur.Reputation,
    ur.PostsCreated,
    ur.QuestionsCreated,
    ur.AnswersCreated,
    re.EditCount,
    re.AvgTimeSinceEdit
FROM 
    TagCounts tc
JOIN 
    UserReputation ur ON ur.PostsCreated > 0  -- Only interested in users who created posts
LEFT JOIN 
    RecentEdits re ON re.UserId = ur.UserId
WHERE 
    tc.PostCount > 100  -- Select tags with more than 100 associated posts
ORDER BY 
    tc.PostCount DESC, ur.Reputation DESC;
