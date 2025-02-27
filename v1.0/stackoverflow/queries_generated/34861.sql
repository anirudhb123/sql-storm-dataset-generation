WITH RecursivePostCTE AS (
    -- Get all answers and their depths based on the parent relationship
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        0 AS Depth
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with Questions only

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        cte.Depth + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE cte ON p.ParentId = cte.PostId
    WHERE 
        p.PostTypeId = 2  -- Only Answers
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
),

PostAnalysis AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.AnswerCount,
        p.ViewCount,
        p.OwnerUserId,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 
            ELSE 0 
        END AS IsAccepted,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
    FROM 
        Posts p
)

SELECT 
    paa.PostId,
    paa.Title,
    paa.CreationDate,
    paa.ViewCount,
    paa.CommentCount,
    paa.IsAccepted,
    u.DisplayName AS Author,
    u.Reputation,
    u.Rank AS UserRank,
    COALESCE(p.ChildCount, 0) AS ChildCount
FROM 
    PostAnalysis paa
LEFT JOIN 
    UserReputation u ON paa.OwnerUserId = u.UserId
LEFT JOIN (
    SELECT 
        c.PostId,
        COUNT(*) AS ChildCount 
    FROM 
        RecursivePostCTE c
    GROUP BY 
        c.PostId
) p ON paa.PostId = p.PostId
WHERE 
    paa.ViewCount > 1000 AND 
    paa.CreationDate > NOW() - INTERVAL '1 year'
ORDER BY 
    paa.ViewCount DESC, u.Reputation DESC
LIMIT 100
OFFSET 0;

-- To include potential NULL logic and string operations, an additional selective filtering
AND 
    (u.Location IS NOT NULL AND u.Location != '' OR 
    (u.Location IS NULL AND paa.Title LIKE '%help%'))
;
