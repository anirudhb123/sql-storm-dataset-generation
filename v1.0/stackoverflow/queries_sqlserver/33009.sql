
;WITH PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.ParentId,
        1 AS Level
    FROM 
        Posts AS p
    WHERE 
        p.PostTypeId = 1 
    UNION ALL 
    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts AS p
    INNER JOIN 
        PostHierarchy AS ph ON p.ParentId = ph.PostId 
    WHERE 
        ph.Level < 5 
),
AnswerStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(a.Id) AS TotalAnswers,
        AVG(a.Score) AS AvgAnswerScore
    FROM 
        Posts AS p
    LEFT JOIN 
        Posts AS a ON a.ParentId = p.Id AND a.PostTypeId = 2 
    GROUP BY 
        p.Id
),
VoteStatistics AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts AS p
    LEFT JOIN 
        Votes AS v ON v.PostId = p.Id
    GROUP BY 
        p.Id
)
SELECT 
    ph.PostId,
    ph.Title,
    ph.Level,
    ah.TotalAnswers,
    ah.AvgAnswerScore,
    vs.UpVotes,
    vs.DownVotes,
    CASE 
        WHEN ah.TotalAnswers > 0 THEN 
            ROUND(CAST(vs.UpVotes AS DECIMAL(10, 2)) / NULLIF((vs.UpVotes + vs.DownVotes), 0) * 100, 2)
        ELSE 
            NULL
    END AS UpvotePercentage,
    COUNT(DISTINCT c.Id) AS CommentCount,
    MAX(c.CreationDate) AS LatestComment
FROM 
    PostHierarchy AS ph
LEFT JOIN 
    AnswerStats AS ah ON ph.PostId = ah.PostId
LEFT JOIN 
    VoteStatistics AS vs ON ph.PostId = vs.PostId
LEFT JOIN 
    Comments AS c ON c.PostId = ph.PostId
GROUP BY 
    ph.PostId, ph.Title, ph.Level, ah.TotalAnswers, ah.AvgAnswerScore, vs.UpVotes, vs.DownVotes
ORDER BY 
    ph.Level, ph.PostId;
