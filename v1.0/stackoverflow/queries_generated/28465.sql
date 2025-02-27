WITH UserPostHistory AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(v.VoteCount) AS AvgVotesPerPost
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS VoteCount 
         FROM Votes 
         GROUP BY PostId) v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsWithTag,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersWithTag
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
PostHistoryCount AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS HistoryCount,
        MAX(ph.CreationDate) AS LastModified
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
),
FinalResults AS (
    SELECT 
        uph.UserId,
        uph.DisplayName,
        uph.TotalPosts,
        uph.QuestionCount,
        uph.AnswerCount,
        uph.AvgVotesPerPost,
        ts.TagName,
        ts.PostCount,
        ts.QuestionsWithTag,
        ts.AnswersWithTag,
        phc.HistoryCount,
        phc.LastModified
    FROM 
        UserPostHistory uph
    LEFT JOIN 
        TagStatistics ts ON uph.QuestionCount > 0
    LEFT JOIN 
        PostHistoryCount phc ON phc.PostId = uph.QuestionCount
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    QuestionCount,
    AnswerCount,
    AvgVotesPerPost,
    TagName,
    PostCount,
    QuestionsWithTag,
    AnswersWithTag,
    HistoryCount,
    LastModified
FROM 
    FinalResults
ORDER BY 
    TotalPosts DESC, 
    QuestionCount DESC;
