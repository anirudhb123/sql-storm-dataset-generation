WITH RecursivePostHistory AS (
    -- Recursive CTE to get all post history for questions and answers
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RevNum
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        p.PostTypeId IN (1, 2)  -- Including only Questions (1) and Answers (2)
),
QuestionStats AS (
    -- Aggregate statistics on questions
    SELECT 
        p.Id AS QuestionId,
        COUNT(a.Id) AS AnswerCount,
        MAX(p.Score) AS MaxScore,
        AVG(p.ViewCount) AS AvgViewCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId  -- Join to get answers related to questions
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  -- Only Questions
    GROUP BY 
        p.Id
),
UserBadgeCounts AS (
    -- Count the number of badges per user
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
-- Final selection of results
SELECT 
    qs.QuestionId,
    qs.AnswerCount,
    qs.MaxScore,
    qs.AvgViewCount,
    qs.TotalUpVotes,
    qs.TotalDownVotes,
    ubc.BadgeCount,
    COALESCE(RPH.UserId, -1) AS LastEditorId,
    COALESCE(RPH.CreationDate, '1970-01-01') AS LastEditDate  -- Handling NULL values
FROM 
    QuestionStats qs
LEFT JOIN 
    UserBadgeCounts ubc ON qs.QuestionId = ubc.UserId
LEFT JOIN 
    (SELECT DISTINCT ON (PostId)
        PostId,
        UserId,
        CreationDate
     FROM 
        RecursivePostHistory
     WHERE 
        RevNum = 1  -- Get the most recent post history entry
     ORDER BY 
        PostId, CreationDate DESC) AS RPH ON qs.QuestionId = RPH.PostId
WHERE 
    qs.AvgViewCount IS NOT NULL  -- Ensuring no division by zero in calculations
ORDER BY 
    qs.MaxScore DESC, 
    qs.AnswerCount DESC;
