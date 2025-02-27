WITH RecursivePosts AS (
    SELECT Id, Title, ParentId, ViewCount, CreationDate,
           ROW_NUMBER() OVER (PARTITION BY Id ORDER BY CreationDate DESC) AS rn
    FROM Posts
    WHERE PostTypeId = 2  -- Only include Answers
),
AggregatedVotes AS (
    SELECT PostId,
           SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
           SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
           COUNT(*) AS TotalVotes
    FROM Votes
    GROUP BY PostId
),
PostHistoryDetails AS (
    SELECT ph.PostId, 
           STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
           MAX(ph.CreationDate) AS LastModified
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId
),
TopTags AS (
    SELECT t.Id, 
           t.TagName, 
           COUNT(p.Id) AS PostCount
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.Id, t.TagName
    ORDER BY PostCount DESC
    LIMIT 10
),
UserPostStats AS (
    SELECT u.Id AS UserId, 
           u.DisplayName,
           COUNT(DISTINCT p.Id) AS PostCount,
           SUM(COALESCE(phd.HistoryTypes IS NOT NULL, 0)) AS Edits,
           SUM(COALESCE(av.Upvotes, 0)) AS TotalUpvotes,
           SUM(COALESCE(av.Downvotes, 0)) AS TotalDownvotes
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN PostHistoryDetails phd ON p.Id = phd.PostId
    LEFT JOIN AggregatedVotes av ON p.Id = av.PostId
    GROUP BY u.Id, u.DisplayName
),
FinalOutput AS (
    SELECT ups.UserId, 
           ups.DisplayName,
           ups.PostCount, 
           ups.Edits,
           ups.TotalUpvotes,
           ups.TotalDownvotes,
           RANK() OVER (ORDER BY ups.PostCount DESC) AS UserRank
    FROM UserPostStats ups
    WHERE ups.PostCount > 0
)

SELECT f.UserId,
       f.DisplayName,
       f.PostCount,
       f.Edits,
       f.TotalUpvotes,
       f.TotalDownvotes,
       f.UserRank,
       COALESCE(tg.TagName, 'No tags') AS TopTag
FROM FinalOutput f
LEFT JOIN TopTags tg ON f.UserId = (SELECT OwnerUserId FROM Posts WHERE Tags LIKE '%' || tg.TagName || '%')
WHERE f.UserRank <= 10
ORDER BY f.UserRank, f.TotalUpvotes DESC;
