WITH RecursivePostHistory AS (
    -- CTE to fetch the history of posts, recursively getting each post's ancestors if it's an answer
    SELECT ph.PostId, ph.CreationDate, ph.UserId, ph.UserDisplayName, 
           ph.PostHistoryTypeId, ph.Comment, 
           1 AS Level
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 24  -- Filter for "Suggested Edit Applied"
    
    UNION ALL
    
    SELECT ph.PostId, ph.CreationDate, ph.UserId, ph.UserDisplayName, 
           ph.PostHistoryTypeId, ph.Comment, 
           Level + 1
    FROM PostHistory ph
    INNER JOIN RecursivePostHistory rph ON ph.PostId = rph.PostId
    WHERE ph.PostHistoryTypeId = 10  -- Adjusting to check for "Post Closed"
)

-- Fetching user statistics and post details
SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
    AVG(p.Score) AS AvgPostScore,
    SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS PostsClosed,
    MAX(ph.CreationDate) AS LastPostHistoryDate,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags
FROM Users u
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN PostHistory ph ON p.Id = ph.PostId
LEFT JOIN Tags t ON t.WikiPostId = p.Id OR t.ExcerptPostId = p.Id
LEFT JOIN RecursivePostHistory rph ON rph.UserId = u.Id
WHERE u.Reputation > 1000 -- Only consider reputable users
  AND (ph.PostHistoryTypeId IN (10, 24) OR ph.PostHistoryTypeId IS NULL)
GROUP BY u.Id
ORDER BY u.Reputation DESC
LIMIT 50;

-- Provide rankings for top posts by views, including potential duplicates
SELECT 
    p.Id AS PostId,
    p.Title,
    p.ViewCount,
    RANK() OVER (ORDER BY p.ViewCount DESC) AS ViewRank,
    COALESCE(d.DuplicateCount, 0) AS DuplicateCount
FROM Posts p
LEFT JOIN (
    SELECT pl.PostId, COUNT(*) AS DuplicateCount
    FROM PostLinks pl
    WHERE pl.LinkTypeId = 3 -- Count only duplicates
    GROUP BY pl.PostId
) d ON p.Id = d.PostId
WHERE COALESCE(d.DuplicateCount, 0) < 5 -- Filter out posts with 5 or more duplicates
ORDER BY p.ViewCount DESC
LIMIT 100;

