WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.AcceptedAnswerId,
        p.CreationDate,
        CAST(p.Title AS VARCHAR(MAX)) AS FullTitle,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with questions

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.Title,
        a.ViewCount,
        a.AnswerCount,
        a.AcceptedAnswerId,
        a.CreationDate,
        CAST(r.FullTitle + ' -> ' + a.Title AS VARCHAR(MAX)) AS FullTitle,
        r.Level + 1
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostHierarchy r ON a.ParentId = r.PostId
)

, PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS Owner,
        COALESCE(v.VoteCount, 0) AS VoteCount,
        RANK() OVER (ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  -- Only questions
)

SELECT 
    r.PostId,
    r.FullTitle,
    p.ViewCount,
    p.AnswerCount,
    p.Owner,
    p.VoteCount,
    CASE 
        WHEN p.VoteCount > 10 THEN 'Highly Voted'
        WHEN p.VoteCount BETWEEN 5 AND 10 THEN 'Moderately Voted'
        ELSE 'Low Votes'
    END AS VoteCategory
FROM 
    RecursivePostHierarchy r
JOIN 
    PopularPosts p ON r.PostId = p.Id
WHERE 
    r.Level = 1  -- Only root level posts
ORDER BY 
    p.ViewRank, 
    r.CreationDate DESC
FETCH FIRST 20 ROWS ONLY;

