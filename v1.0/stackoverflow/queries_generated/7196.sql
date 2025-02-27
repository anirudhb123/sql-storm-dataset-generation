WITH BadgeCounts AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
), 
UserReputation AS (
    SELECT Id, Reputation, CreationDate, Location, AboutMe, Views, UpVotes, DownVotes
    FROM Users
), 
PopularPosts AS (
    SELECT OwnerUserId, COUNT(*) AS PostCount, SUM(ViewCount) AS TotalViews
    FROM Posts
    GROUP BY OwnerUserId
    HAVING COUNT(*) > 10 AND SUM(ViewCount) > 1000
), 
PostDetails AS (
    SELECT p.Id AS PostId, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId, p.LastActivityDate, 
           pt.Name AS PostType, 
           (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
           (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS Upvotes,
           (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS Downvotes
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
), 
ActiveUsers AS (
    SELECT U.Id AS UserId, U.DisplayName, U.Reputation, U.LastAccessDate, 
           BC.BadgeCount, PP.PostCount, PP.TotalViews
    FROM UserReputation U
    LEFT JOIN BadgeCounts BC ON U.Id = BC.UserId
    LEFT JOIN PopularPosts PP ON U.Id = PP.OwnerUserId 
)
SELECT AU.UserId, AU.DisplayName, AU.Reputation, AU.LastAccessDate, AU.BadgeCount, 
       COALESCE(PD.PostCount, 0) AS ActivePostCount, COALESCE(PD.TotalViews, 0) AS TotalPostViews,
       pd.Title, pd.CreationDate, pd.Score, pd.CommentCount, pd.Upvotes, pd.Downvotes
FROM ActiveUsers AU
LEFT JOIN PopularPosts PP ON AU.UserId = PP.OwnerUserId
LEFT JOIN PostDetails PD ON AU.UserId = PD.OwnerUserId
ORDER BY AU.Reputation DESC, PD.Score DESC
LIMIT 50;
