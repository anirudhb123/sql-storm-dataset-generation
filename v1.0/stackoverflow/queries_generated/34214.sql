WITH RecursivePostChain AS (
    SELECT 
        p.Id AS PostId, 
        p.Title AS PostTitle, 
        p.OwnerUserId, 
        1 AS Depth
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions

    UNION ALL

    SELECT 
        p.InnerPostId AS PostId, 
        p.Title AS PostTitle, 
        p.OwnerUserId, 
        Depth + 1
    FROM 
        Posts p
    INNER JOIN 
        Posts ans ON p.Id = ans.ParentId
    WHERE 
        ans.PostTypeId = 2  -- Only answers
)

SELECT 
    up.DisplayName AS UserName,
    COUNT(DISTINCT rp.PostId) AS TotalQuestions,
    COUNT(rp.*) AS TotalAnswers,
    AVG(DATEDIFF(second, rp.CreationDate, COALESCE(rp.ClosedDate, GETDATE()))) AS AvgTimeOpenInSeconds,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    ROW_NUMBER() OVER(ORDER BY COUNT(rp.PostId) DESC) AS Rank
FROM 
    RecursivePostChain rp
LEFT JOIN 
    Users up ON rp.OwnerUserId = up.Id
LEFT JOIN 
    Tags t ON rp.Tags LIKE '%' + t.TagName + '%'
WHERE 
    rp.PostId IS NOT NULL
GROUP BY 
    up.DisplayName
HAVING 
    COUNT(DISTINCT rp.PostId) > 0 
ORDER BY 
    Rank;

-- Additional Performance Measurement
SELECT 
    PH.PostHistoryTypeId,
    COUNT(*) AS ChangeCount,
    SUM(CASE WHEN PH.CreationDate > DATEADD(month, -6, GETDATE()) THEN 1 ELSE 0 END) AS RecentChanges,
    CASE 
        WHEN PH.PostHistoryTypeId IN (10, 11) THEN 'Closure'
        ELSE 'Other Changes'
    END AS ChangeType
FROM 
    PostHistory PH
GROUP BY 
    PH.PostHistoryTypeId
ORDER BY 
    ChangeCount DESC;

-- Cross Join Aggregation with NULL Logic
SELECT 
    p.Title, 
    COALESCE(NULLIF(p.ViewCount, 0), 1) AS AdjustedViewCount,
    p.Score,
    uh.UserId AS VotingUserId
FROM 
    Posts p
CROSS JOIN 
    (SELECT DISTINCT UserId FROM Votes) uh
WHERE 
    p.Score >= 0
ORDER BY 
    AdjustedViewCount DESC, 
    p.Score DESC;
