WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        p.AcceptedAnswerId,
        0 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Starting with Questions
    UNION ALL
    SELECT 
        p2.Id,
        p2.Title,
        p2.OwnerUserId,
        p2.PostTypeId,
        p2.AcceptedAnswerId,
        Level + 1
    FROM Posts p2
    INNER JOIN RecursivePostHierarchy r ON p2.ParentId = r.PostId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS QuestionCount,
    COUNT(DISTINCT a.Id) AS AnswerCount,
    COALESCE(SUM(v.Score), 0) AS TotalVotes,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    MAX(p.LastActivityDate) AS LastActivity
FROM Users u
LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 -- Questions
LEFT JOIN Posts a ON p.Id = a.ParentId -- Answers to Questions
LEFT JOIN Votes v ON v.PostId IN (SELECT Id FROM RecursivePostHierarchy WHERE PostId = p.Id)
LEFT JOIN LATERAL (
    SELECT DISTINCT 
        TRIM(regexp_split_to_table(p.Tags, '><')) AS TagName
    ) t ON true
WHERE 
    u.Reputation > 1000
    AND p.LastActivityDate >= NOW() - INTERVAL '1 year'
GROUP BY u.Id, u.DisplayName, u.Reputation
HAVING COUNT(DISTINCT p.Id) > 0 
   AND COALESCE(SUM(v.Score), 0) > 0
ORDER BY Reputation DESC
LIMIT 10;

-- Additional Analysis on Closed Posts
WITH ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        COUNT(*) AS CloseCount,
        MAX(ph.CreationDate) AS LastCloseDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10 -- Posts closed
    GROUP BY ph.PostId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    cp.CloseCount,
    cp.LastCloseDate
FROM Posts p
LEFT JOIN ClosedPosts cp ON p.Id = cp.PostId
WHERE cp.CloseCount IS NOT NULL
ORDER BY CloseCount DESC
LIMIT 5;
