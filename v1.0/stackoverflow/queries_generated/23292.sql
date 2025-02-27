WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY CASE 
            WHEN u.Reputation < 50 THEN 'Bronze'
            WHEN u.Reputation < 250 THEN 'Silver'
            ELSE 'Gold'
        END ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RecentAction
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '30 days'
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        pm.Reason,
        ph.CreationDate AS CloseDate
    FROM 
        Posts p
    INNER JOIN (
        SELECT 
            ph.PostId,
            CASE 
                WHEN ph.Comment IS NULL THEN 'Unknown reason'
                ELSE (SELECT cr.Name FROM CloseReasonTypes cr WHERE cr.Id = ph.Comment::int)
            END AS Reason
        FROM 
            PostHistory ph
        WHERE 
            ph.PostHistoryTypeId = 10
    ) pm ON p.Id = pm.PostId
    INNER JOIN RecentPostHistory rph ON p.Id = rph.PostId
    WHERE 
        rph.PostHistoryTypeId IN (10, 11) -- closed or reopened
),
UserActions AS (
    SELECT 
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsClosed
    FROM 
        Users u
    JOIN 
        RecentPostHistory rph ON u.Id = rph.UserId
    JOIN 
        ClosedPosts cp ON cp.PostId = rph.PostId
    GROUP BY 
        u.DisplayName
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    ua.PostsClosed,
    CASE 
        WHEN ua.PostsClosed IS NULL THEN 'No closures'
        WHEN ua.PostsClosed > 0 THEN 'Posts Closed: ' || ua.PostsClosed
        ELSE 'Zero Closed'
    END AS ClosureSummary
FROM 
    RankedUsers u
LEFT JOIN 
    UserActions ua ON u.DisplayName = ua.DisplayName
WHERE 
    u.Rank <= 5
ORDER BY 
    u.Reputation DESC;

WITH RecursiveTagExploration AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        1 AS Level,
        ARRAY[t.TagName] AS Path
    FROM 
        Tags t
    WHERE 
        EXISTS (SELECT 1 FROM Posts p WHERE p.Tags LIKE '%' || t.TagName || '%')
    UNION ALL
    SELECT 
        t.Id,
        t.TagName,
        re.Level + 1,
        re.Path || t.TagName
    FROM 
        RecursiveTagExploration re
    JOIN 
        Posts p ON p.Tags LIKE '%' || ANY(re.Path) || '%'
    JOIN 
        Tags t ON t.TagName <> ALL(re.Path)
    WHERE 
        re.Level < 5
)
SELECT 
    rt.TagName,
    rt.Level,
    rt.Path,
    COUNT(DISTINCT p.Id) AS RelatedPosts
FROM 
    RecursiveTagExploration rt
LEFT JOIN 
    Posts p ON p.Tags LIKE '%' || rt.TagName || '%'
GROUP BY 
    rt.TagName, rt.Level, rt.Path
ORDER BY 
    rt.Level, RelatedPosts DESC
LIMIT 10;
