WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        0 AS Level,
        CAST(p.Title AS VARCHAR(MAX)) AS FullPath
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.Title,
        a.Score,
        a.CreationDate,
        a.OwnerUserId,
        rp.Level + 1 AS Level,
        CAST(rp.FullPath + ' > ' + a.Title AS VARCHAR(MAX)) AS FullPath
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostCTE rp ON a.ParentId = rp.PostId
    WHERE 
        a.PostTypeId = 2 -- Only answers
),
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId IN (6, 7) THEN 1 END) AS CloseVotes,
        COUNT(CASE WHEN v.VoteTypeId = 5 THEN 1 END) AS Favorites
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    r.PostId,
    r.Title AS QuestionTitle,
    r.Score AS QuestionScore,
    r.CreationDate AS QuestionCreationDate,
    r.OwnerUserId AS QuestionOwnerId,
    ps.UpVotes,
    ps.DownVotes,
    ps.CloseVotes,
    ps.Favorites,
    r.Level,
    r.FullPath
FROM 
    RecursivePostCTE r
LEFT JOIN 
    PostVoteSummary ps ON r.PostId = ps.PostId
WHERE 
    r.Level = 0 -- Only top-level questions
    AND r.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Filter for posts created in the last year
ORDER BY 
    r.Score DESC,
    ps.UpVotes DESC
OPTION (MAXRECURSION 1000);

This SQL query provides a performance benchmark by combining recursive CTEs to traverse question-answer hierarchies, aggregating vote statistics with a summary table, and filtering for recent questions. It employs complex expressions and NULL logic while optimizing the output for performance analysis.
