WITH RecentQuestions AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        AVG(v.BountyAmount) FILTER (WHERE v.BountyAmount IS NOT NULL) AS AvgBounty
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    WHERE 
        p.PostTypeId = 1 -- Questions
        AND p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, u.DisplayName
),
ClosedQuestions AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate,
        ARRAY_AGG(DISTINCT ctr.Name) AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ctr ON ph.Comment::INT = ctr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    rq.QuestionId,
    rq.Title,
    rq.CreationDate,
    rq.OwnerDisplayName,
    rq.AnswerCount,
    cq.LastClosedDate,
    CASE 
        WHEN cq.LastClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS QuestionStatus,
    COALESCE(rq.AvgBounty, 0) AS AvgBounty,
    CASE 
        WHEN ARRAY_LENGTH(cq.CloseReasons, 1) > 0 THEN 'Reasons: ' || STRING_AGG(cq.CloseReasons::text, ', ')
        ELSE 'No close reasons'
    END AS CloseReasonDetails
FROM 
    RecentQuestions rq
LEFT JOIN 
    ClosedQuestions cq ON rq.QuestionId = cq.PostId
ORDER BY 
    rq.AnswerCount DESC NULLS LAST, 
    rq.CreationDate DESC
LIMIT 100;

### Explanation:
1. **CTEs**: Two Common Table Expressions (CTEs) are used—`RecentQuestions` gathers recent questions with their owners, counts, and average bounties; `ClosedQuestions` collects details of closed questions, including the last closed date and reasons.
  
2. **Joins**: The main query utilizes LEFT JOIN to relate recent questions to their closed question details, allowing for open and closed questions to be displayed.

3. **Aggregations**: Aggregation functions like `COUNT()` and `AVG()` are used, and `ARRAY_AGG()` to collect close reasons into an array.

4. **CASE Statements**: Used to determine the status of questions (Open/Closed) and to format close reason details dynamically.

5. **Filtering**: The filtering conditions ensure that only questions from the last 30 days are considered, addressing temporal data constraints.

6. **Ordering and Limiting**: The output is ordered by the answer count (descending) and latest creation date, providing a logical view of trending questions.

7. **NULL Handling**: NULLs are handled explicitly, with `COALESCE()` providing default values where necessary. 

This query showcases a blend of various SQL functionalities and complexities that are useful for performance benchmarking.
