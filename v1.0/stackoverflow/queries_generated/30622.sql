WITH RecursiveCTE AS (
    -- Recursive CTE to find all the answers to each question along with their scores
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.Score AS QuestionScore,
        p.CreationDate AS QuestionDate,
        a.Id AS AnswerId,
        a.Score AS AnswerScore,
        1 AS Level
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1
    
    UNION ALL
    
    SELECT 
        c.QuestionId,
        c.Title,
        c.QuestionScore,
        c.QuestionDate,
        a.Id AS AnswerId,
        a.Score AS AnswerScore,
        Level + 1
    FROM 
        RecursiveCTE c
    JOIN 
        Posts a ON c.AnswerId = a.ParentId
    WHERE 
        a.PostTypeId = 2
),
PostAggregate AS (
    -- Aggregate votes for questions and answers
    SELECT 
        p.Id,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PostHistoryFiltered AS (
    -- Filter post history for closed posts with certain reasons
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        COUNT(*) OVER (PARTITION BY ph.PostId) AS HistoryCount
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON CAST(ph.Comment AS INT) = crt.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed and Reopened posts
)
-- Main SELECT using the CTEs
SELECT 
    q.Id AS QuestionId,
    q.Title AS QuestionTitle,
    q.QuestionScore,
    q.QuestionDate,
    a.AnswerId,
    a.AnswerScore,
    pa.UpVotes,
    pa.DownVotes,
    pa.TotalVotes,
    MultipleHistory.HistoryCount AS ClosedHistoryCount,
    CASE 
        WHEN q.Score IS NULL THEN 'No Score'
        ELSE CAST((q.Score - COALESCE(a.AnswerScore, 0)) AS VARCHAR)
    END AS ScoreDifference
FROM 
    RecursiveCTE q
LEFT JOIN 
    PostAggregate pa ON q.QuestionId = pa.Id
LEFT JOIN 
    PostHistoryFiltered MultipleHistory ON q.QuestionId = MultipleHistory.PostId
WHERE 
    q.Level = 1
ORDER BY 
    q.QuestionDate DESC, 
    q.QuestionScore DESC;
This SQL query performs a comprehensive analysis of questions and their answers while demonstrating the utilization of several advanced SQL techniques such as recursive CTEs, window functions, outer joins, conditional aggregation, and filtering based on specific post history. The query retrieves details about each question, its answers, the total votes, and the post history concerning close and reopen actions, creating an insightful set of metrics that can be used for performance benchmarking.
