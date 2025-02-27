WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
QuestionsWithAcceptedAnswers AS (
    SELECT 
        q.Id AS QuestionId,
        q.Title,
        a.Id AS AcceptedAnswerId,
        COALESCE(a.Score, 0) AS AcceptedScore,
        COALESCE(a.ViewCount, 0) AS AnswerViewCount
    FROM 
        Posts q
    LEFT JOIN 
        Posts a ON q.AcceptedAnswerId = a.Id
    WHERE 
        q.PostTypeId = 1
),
RankedUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalPosts,
        us.TotalQuestions,
        us.TotalAnswers,
        us.TotalBadges,
        RANK() OVER (ORDER BY us.TotalPosts DESC, us.TotalQuestions DESC) AS UserRank
    FROM 
        UserStats us
),
FilteredQuestions AS (
    SELECT 
        q.QuestionId,
        q.Title,
        q.AcceptedAnswerId,
        RANK() OVER (PARTITION BY q.AcceptedAnswerId ORDER BY q.AcceptedScore DESC) AS QuestionRank
    FROM 
        QuestionsWithAcceptedAnswers q
    WHERE 
        q.AcceptedAnswerId IS NOT NULL
)
SELECT 
    u.DisplayName AS UserName,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    u.TotalBadges,
    COALESCE(q.Title, 'No Accepted Questions') AS AcceptedQuestionTitle,
    q.AcceptedScore,
    q.AnswerViewCount,
    COALESCE(q.QuestionRank, 100) AS QuestionRank
FROM 
    RankedUsers u
LEFT JOIN 
    FilteredQuestions q ON u.UserId = (SELECT p.OwnerUserId FROM Posts p WHERE p.Id = q.AcceptedAnswerId)
WHERE 
    u.UserRank <= 10
ORDER BY 
    u.UserRank, 
    q.QuestionRank;
