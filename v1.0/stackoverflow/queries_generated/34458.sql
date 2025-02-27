WITH RecursivePostScores AS (
    -- CTE to calculate post scores recursively for answers
    SELECT 
        p.Id AS PostId,
        (COALESCE(p.Score, 0) + COALESCE(p.AnswerCount * 5, 0)) AS TotalScore,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 2  -- Answers
    
    UNION ALL
    
    SELECT 
        p.Id AS PostId,
        (COALESCE(p.Score, 0) + COALESCE(p.AnswerCount * 5, 0) + r.TotalScore) AS TotalScore,
        Level + 1
    FROM Posts p
    JOIN RecursivePostScores r ON p.AcceptedAnswerId = r.PostId
    WHERE r.Level < 10  -- Limit to a maximum of 10 levels
),
SelectedPosts AS (
    -- CTE to select recent questions and their related answers
    SELECT 
        q.Id AS QuestionId,
        q.Title AS QuestionTitle,
        q.Score AS QuestionScore,
        ARRAY_AGG(DISTINCT a.Id) AS AnswerIds,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        MAX(a.CreationDate) AS LastAnswerDate
    FROM Posts q
    LEFT JOIN Posts a ON q.Id = a.ParentId
    WHERE q.PostTypeId = 1  -- Questions
    GROUP BY q.Id
),
UserEngagement AS (
    -- CTE that captures the engagement of users based on votes
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COALESCE(COUNT(DISTINCT h.PostId), 0) AS HistoryActions
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN PostHistory h ON u.Id = h.UserId
    GROUP BY u.Id
),
VotesSummary AS (
    -- Summarize votes for relevant posts
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownvoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 6 THEN 1 END) AS CloseVoteCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
)
SELECT 
    sp.QuestionId,
    sp.QuestionTitle,
    sp.QuestionScore,
    up.Upvotes,
    up.Downvotes,
    sp.AnswerCount,
    vs.UpvoteCount,
    vs.DownvoteCount,
    vs.CloseVoteCount,
    rps.TotalScore AS AnswerScore,
    COALESCE(rps.TotalScore, 0) AS FinalScore
FROM SelectedPosts sp
LEFT JOIN UserEngagement up ON up.UserId = sp.QuestionId
LEFT JOIN VotesSummary vs ON vs.PostId = sp.QuestionId
LEFT JOIN RecursivePostScores rps ON rps.PostId = ANY(sp.AnswerIds)
WHERE 
    sp.LastAnswerDate > NOW() - INTERVAL '30 days' -- Only include recent questions
    AND (sp.AnswerCount > 0 OR up.Upvotes > up.Downvotes)
ORDER BY 
    FinalScore DESC
LIMIT 10;
