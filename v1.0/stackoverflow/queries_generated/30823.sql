WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Select only questions

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.Title,
        a.OwnerUserId,
        a.CreationDate,
        rp.Level + 1
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostCTE rp ON rp.PostId = a.ParentId
    WHERE 
        a.PostTypeId = 2  -- Select only answers
)
SELECT 
    p.Title AS QuestionTitle,
    u.DisplayName AS UserDisplayName,
    COUNT(a.id) AS AnswerCount,
    AVG(v.BountyAmount) AS AverageBounty,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    MAX(COALESCE(c.Score, 0)) AS HighestCommentScore,
    DATE_TRUNC('month', p.CreationDate) AS Month,
    ROW_NUMBER() OVER (PARTITION BY DATE_TRUNC('month', p.CreationDate) ORDER BY p.CreationDate DESC) AS MonthRank
FROM 
    RecursivePostCTE p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Posts a ON a.ParentId = p.PostId  -- Join to count answers
LEFT JOIN 
    Votes v ON v.PostId = p.PostId AND v.VoteTypeId IN (8, 9)  -- Bounty votes
LEFT JOIN 
    Comments c ON c.PostId = p.PostId  -- Join to get comment scores
LEFT JOIN 
    LATERAL (
        SELECT 
            t.TagName 
        FROM 
            Tags t 
        WHERE 
            t.ExcerptPostId = p.PostId
    ) t ON TRUE
WHERE 
    u.Reputation IS NOT NULL
GROUP BY 
    p.Title, 
    u.DisplayName, 
    DATE_TRUNC('month', p.CreationDate)
HAVING 
    COUNT(a.Id) > 0  -- Only include questions with answers
ORDER BY 
    Month DESC, 
    AverageBounty DESC;
