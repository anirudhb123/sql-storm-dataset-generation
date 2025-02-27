WITH RecursivePostHierarchy AS (
    SELECT p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.AcceptedAnswerId, 
           CAST(p.Title AS varchar(1000)) AS FullTitle,
           0 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Questions

    UNION ALL

    SELECT p2.Id, p2.Title, p2.OwnerUserId, p2.CreationDate, p2.AcceptedAnswerId, 
           CAST(r.FullTitle || ' -> ' || p2.Title AS varchar(1000)) AS FullTitle,
           r.Level + 1
    FROM Posts p2
    INNER JOIN RecursivePostHierarchy r ON p2.ParentId = r.Id
    WHERE p2.PostTypeId = 2  -- Answers
)

SELECT 
    u.DisplayName AS UserName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT ph.Id) AS TotalPostHistory,
    SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseReopenCount,
    AVG(DATEDIFF(day, p.CreationDate, GETDATE())) AS AvgPostAge,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags,
    ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COUNT(DISTINCT p.Id) DESC) AS UserRank
FROM Users u
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN PostHistory ph ON p.Id = ph.PostId
LEFT JOIN Tags t ON t.Id = ANY(STRING_TO_ARRAY(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags)-2), '><')::int[])
WHERE p.CreationDate >= GETDATE() - INTERVAL '1 year' -- Filter posts from the last year
GROUP BY u.Id, u.DisplayName
HAVING COUNT(DISTINCT p.Id) >= 5  -- Only include users with at least 5 posts
ORDER BY TotalPosts DESC, UserRank;

