WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(p.Id) AS PostCount, 
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount, 
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount, 
        SUM(p.Score) AS TotalScore,
        AVG(v.TotalVotes) AS AverageVotes,
        MAX(p.CreationDate) AS MostRecentPost
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS TotalVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
TagStats AS (
    SELECT 
        t.TagName, 
        COUNT(p.Id) AS PostCount, 
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount, 
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY 
        t.TagName
),
PostHistoryStats AS (
    SELECT 
        ph.UserId, 
        COUNT(ph.Id) AS EditCount, 
        SUM(CASE WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN 1 ELSE 0 END) AS EditsMade,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS PostsClosed,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS PostsReopened
    FROM 
        PostHistory ph
    GROUP BY 
        ph.UserId
)

SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.PostCount,
    ups.QuestionCount,
    ups.AnswerCount,
    ups.TotalScore,
    ups.AverageVotes,
    ups.MostRecentPost,
    ts.PostCount AS TotalPostsPerTag,
    ts.QuestionCount AS TotalQuestionsPerTag,
    ts.AnswerCount AS TotalAnswersPerTag,
    phs.EditCount AS TotalEdits,
    phs.EditsMade,
    phs.PostsClosed,
    phs.PostsReopened
FROM 
    UserPostStats ups
JOIN 
    TagStats ts ON ts.TagName = (SELECT TagName FROM Tags LIMIT 1) -- Example of using a single tag for aggregate
LEFT JOIN 
    PostHistoryStats phs ON ups.UserId = phs.UserId
WHERE 
    ups.PostCount > 0
ORDER BY 
    ups.TotalScore DESC
LIMIT 100;
