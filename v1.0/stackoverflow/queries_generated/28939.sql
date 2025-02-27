WITH TagCounts AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.AnswerCount, 0)) AS TotalAnswers,
        AVG(COALESCE(p.Score, 0)) AS AvgScore
    FROM 
        Tags AS t
    JOIN 
        Posts AS p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%,t.TagName,'%')
    GROUP BY 
        t.TagName
),
HighScorePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswer,
        t.TagName
    FROM 
        Posts AS p
    JOIN 
        Tags AS t ON p.Tags LIKE CONCAT('%<', t.TagName, '>%,t.TagName,'%')
    WHERE 
        p.Score > (SELECT AVG(Score) FROM Posts) 
        AND p.PostTypeId = 1  -- Filter for Questions
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(COALESCE(v.CreationDate, 0)) AS TotalVotes
    FROM 
        Users AS u
    LEFT JOIN 
        Posts AS p ON p.OwnerUserId = u.Id AND p.PostTypeId = 1
    LEFT JOIN 
        Comments AS c ON c.UserId = u.Id
    LEFT JOIN 
        Votes AS v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
ActivitySummary AS (
    SELECT 
        u.DisplayName,
        COUNT(DISTINCT h.PostId) AS EditCount,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users AS u
    JOIN 
        PostHistory AS h ON h.UserId = u.Id
    JOIN 
        Posts AS p ON h.PostId = p.Id
    WHERE 
        h.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        u.DisplayName
)
SELECT 
    tc.TagName,
    tc.PostCount,
    tc.TotalViews,
    tc.TotalAnswers,
    tc.AvgScore,
    hsp.Title,
    hsp.ViewCount AS HighViewCount,
    hsp.Score AS HighScore,
    ua.DisplayName AS User,
    ua.QuestionCount,
    ua.CommentCount,
    asum.EditCount,
    asum.PostCount AS UserPostCount
FROM 
    TagCounts AS tc
LEFT JOIN 
    HighScorePosts AS hsp ON hsp.TagName = tc.TagName
LEFT JOIN 
    UserActivity AS ua ON ua.QuestionCount > 0
LEFT JOIN 
    ActivitySummary AS asum ON asum.UserId = ua.UserId
ORDER BY 
    tc.AvgScore DESC, tc.TotalViews DESC;
