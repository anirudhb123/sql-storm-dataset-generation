WITH UserEngagement AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           COUNT(DISTINCT p.Id) AS PostsCreated,
           SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
           SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
           ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY SUM(COALESCE(v.BountyAmount, 0)) DESC) AS Rank
    FROM Users u
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN Votes v ON v.UserId = u.Id
    LEFT JOIN Comments c ON c.UserId = u.Id
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT UserId, DisplayName, PostsCreated, TotalBounties, TotalCommentScore, Upvotes, Downvotes
    FROM UserEngagement
    WHERE Rank <= 10
)
SELECT tu.DisplayName,
       tu.PostsCreated,
       tu.TotalBounties,
       tu.TotalCommentScore,
       tu.Upvotes,
       tu.Downvotes,
       CASE 
           WHEN tu.TotalBounties > 100 THEN 'High Contributor'
           WHEN tu.TotalBounties BETWEEN 50 AND 100 THEN 'Medium Contributor'
           ELSE 'Low Contributor' 
       END AS ContributorLevel,
       COALESCE((
           SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
           FROM Tags t
           JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
           WHERE p.OwnerUserId = tu.UserId
       ), 'No Tags') AS TopTags,
       CASE 
           WHEN EXISTS (SELECT 1 FROM Badges b WHERE b.UserId = tu.UserId AND b.Class = 1) 
           THEN 'Gold Badge Holder'
           WHEN EXISTS (SELECT 1 FROM Badges b WHERE b.UserId = tu.UserId AND b.Class = 2) 
           THEN 'Silver Badge Holder'
           ELSE 'No Notable Badges' 
       END AS BadgeStatus
FROM TopUsers tu
ORDER BY tu.TotalBounties DESC, tu.Upvotes DESC;
