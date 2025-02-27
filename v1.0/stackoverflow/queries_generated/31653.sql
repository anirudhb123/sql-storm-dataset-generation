WITH RecursivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.OwnerUserId,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.CreationDate,
        p.LastActivityDate,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL -- Top-level posts (questions)

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.Body,
        p.OwnerUserId,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.CreationDate,
        p.LastActivityDate,
        rp.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePosts rp ON p.ParentId = rp.PostId -- Join on parent-child relationship 
)

SELECT 
    u.DisplayName AS UserName,
    r.PostId,
    r.Title AS QuestionTitle,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
    ROW_NUMBER() OVER (PARTITION BY r.OwnerUserId ORDER BY r.LastActivityDate DESC) AS UserPostRank
FROM 
    RecursivePosts r
LEFT JOIN 
    Users u ON r.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON r.PostId = c.PostId 
LEFT JOIN 
    Votes v ON r.PostId = v.PostId
WHERE 
    r.PostTypeId = 1 -- Only considering questions
    AND r.CreationDate >= NOW() - INTERVAL '1 year' -- Questions created in the last year
GROUP BY 
    u.DisplayName, r.PostId, r.Title, r.OwnerUserId, r.LastActivityDate
HAVING 
    COUNT(c.Id) > 5 -- More than 5 comments
ORDER BY 
    UpVoteCount DESC, DownVoteCount ASC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY; -- Pagination for benchmarking

