WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.OwnerUserId, 
        p.Score, 
        0 AS Depth
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
    UNION ALL
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.OwnerUserId, 
        p.Score, 
        Depth + 1 AS Depth
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE r ON p.ParentId = r.PostId
)
, AnswerVoteStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 2 -- Only answers
    GROUP BY 
        p.Id
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    u.DisplayName AS Owner,
    COALESCE(a.VoteCount, 0) AS TotalVotes,
    COALESCE(a.UpVoteCount, 0) AS UpVotes,
    COALESCE(a.DownVoteCount, 0) AS DownVotes,
    DENSE_RANK() OVER (ORDER BY r.Score DESC) AS Rank,
    (
        SELECT 
            COUNT(*)
        FROM 
            Comments c
        WHERE 
            c.PostId = r.PostId
    ) AS CommentCount,
    (
        SELECT 
            STRING_AGG(DISTINCT t.TagName, ', ') 
        FROM 
            UNNEST(STRING_TO_ARRAY(SUBSTRING(r.Tags, 2, LENGTH(r.Tags) - 2), '><')) AS tag
        JOIN 
            Tags t ON t.TagName = tag
    ) AS Tags
FROM 
    RecursivePostCTE r
LEFT JOIN 
    Users u ON r.OwnerUserId = u.Id
LEFT JOIN 
    AnswerVoteStats a ON r.PostId = a.PostId
WHERE 
    r.Depth = 0 -- Only top-level questions
AND 
    r.CreationDate >= NOW() - INTERVAL '1 year' -- Filter for the last year
ORDER BY 
    r.Score DESC, 
    r.CreationDate DESC;
