WITH RecursivePosts AS (
    SELECT Id, Title, Score, ParentId, CreationDate,
           ROW_NUMBER() OVER (PARTITION BY Id ORDER BY CreationDate DESC) as rn
    FROM Posts
    WHERE PostTypeId IN (1, 2) -- Only Questions and Answers
),
UserStats AS (
    SELECT u.Id AS UserId, 
           u.DisplayName,
           SUM(COALESCE(b.Class, 0)) AS TotalBadgeClass, -- Assuming Class from badges indicates significance
           COUNT(DISTINCT ph.PostId) AS TotalPosts,
           COUNT(DISTINCT v.Id) AS TotalVotes,
           COUNT(DISTINCT c.Id) AS TotalComments
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT UserId, DisplayName, TotalBadgeClass, TotalPosts, TotalVotes, TotalComments,
           RANK() OVER (ORDER BY TotalPosts DESC, TotalVotes DESC) as UserRank
    FROM UserStats
),
RecentPostLinks AS (
    SELECT pl.PostId, pl.RelatedPostId, l.Name AS LinkTypeName,
           COUNT(*) AS LinkCount
    FROM PostLinks pl
    JOIN LinkTypes l ON pl.LinkTypeId = l.Id
    WHERE pl.CreationDate >= NOW() - INTERVAL '30 days' -- Limit to recent links
    GROUP BY pl.PostId, pl.RelatedPostId, l.Name
),
PostEdits AS (
    SELECT ph.PostId, 
           COUNT(CASE WHEN ph.PostHistoryTypeId IN (4, 5) THEN 1 END) AS EditCount,  -- Title and body edits
           MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    GROUP BY ph.PostId
)
SELECT p.Id AS PostId, p.Title, p.Score, 
       u.DisplayName AS Owner, 
       u.TotalPosts AS OwnerTotalPosts,
       u.TotalVotes AS OwnerTotalVotes,
       r.LinkTypeName,
       re.EditCount,
       re.LastEditDate
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN RecentPostLinks r ON p.Id = r.PostId
LEFT JOIN PostEdits re ON p.Id = re.PostId
WHERE p.PostTypeId = 1 -- Focus on Questions
  AND p.CreationDate >= NOW() - INTERVAL '6 months' -- Limit to recent questions
  AND u.Reputation > 1000 -- Filter for reputable users
ORDER BY p.CreationDate DESC, p.Score DESC;
