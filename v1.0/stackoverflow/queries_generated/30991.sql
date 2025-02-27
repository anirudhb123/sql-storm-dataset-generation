WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        0 AS Level,
        p.Title,
        p.CreationDate
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.ParentId,
        r.Level + 1,
        p.Title,
        p.CreationDate
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
    WHERE 
        p.PostTypeId = 2  -- Include answers
)
SELECT 
    ph.PostId,
    ph.Title AS QuestionTitle,
    COUNT(DISTINCT p.Id) AS AnswerCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    MAX(b.Date) AS LastBadgeDate,
    CASE 
        WHEN SUM(CASE WHEN ph.Level = 0 THEN 1 END) = 0 THEN 'No Answers'
        ELSE 'Answers Present'
    END AS AnswerStatus
FROM 
    RecursivePostHierarchy ph
LEFT JOIN 
    Posts p ON ph.PostId = p.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostLinks pl ON pl.PostId = p.Id
LEFT JOIN 
    Tags t ON (t.Id = pl.RelatedPostId OR t.Id = p.Id)
LEFT JOIN 
    Badges b ON b.UserId = p.OwnerUserId
GROUP BY 
    ph.PostId, ph.Title
ORDER BY 
    AnswerCount DESC, ph.Title;
