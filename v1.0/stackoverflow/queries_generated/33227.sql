WITH RecursiveTagHierarchy AS (
    SELECT t.Id, t.TagName, t.Count, NULL AS ParentId 
    FROM Tags t
    WHERE t.WikiPostId IS NULL
    
    UNION ALL
    
    SELECT t.Id, t.TagName, t.Count, rt.Id 
    FROM Tags t
    INNER JOIN RecursiveTagHierarchy rt ON rt.Id = t.ExcerptPostId
),
TopUsers AS (
    SELECT u.Id, u.DisplayName, u.Reputation, RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM Users u
    WHERE u.Reputation > 5000
),
PostStats AS (
    SELECT p.OwnerUserId, 
           COUNT(p.Id) AS PostCount, 
           SUM(p.Score) AS TotalScore, 
           AVG(p.ViewCount) AS AvgViewCount,
           COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= '2020-01-01' -- Filter for recent posts
    GROUP BY p.OwnerUserId
),
UserPostActivity AS (
    SELECT u.Id AS UserId, 
           u.DisplayName, 
           COALESCE(ps.PostCount, 0) AS PostCount,
           COALESCE(ps.TotalScore, 0) AS TotalScore,
           COALESCE(ps.CommentCount, 0) AS CommentCount,
           ISNULL(ba.BadgeCount, 0) AS BadgeCount
    FROM Users u
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
    LEFT JOIN (
        SELECT UserId, COUNT(*) AS BadgeCount
        FROM Badges 
        GROUP BY UserId
    ) ba ON u.Id = ba.UserId
),
PopularTags AS (
    SELECT t.TagName, 
           SUM(v.VoteTypeId = 2) AS TotalUpVotes,
           SUM(v.VoteTypeId = 3) AS TotalDownVotes
    FROM Tags t
    INNER JOIN Posts p ON t.Id = p.Id
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE t.IsModeratorOnly = 0
    GROUP BY t.TagName
),
FinalResults AS (
    SELECT up.DisplayName, up.PostCount, up.TotalScore, up.CommentCount, 
           pt.TagName, pt.TotalUpVotes, pt.TotalDownVotes
    FROM UserPostActivity up
    CROSS JOIN PopularTags pt 
    WHERE up.PostCount > 10
)
SELECT 
    fr.DisplayName,
    fr.PostCount, 
    fr.TotalScore,
    fr.CommentCount,
    fr.TagName,
    fr.TotalUpVotes,
    fr.TotalDownVotes,
    CASE 
        WHEN fr.TotalUpVotes > fr.TotalDownVotes THEN 'Positive'
        WHEN fr.TotalDownVotes > fr.TotalUpVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS TagVoteSentiment
FROM FinalResults fr
ORDER BY fr.TotalScore DESC, fr.PostCount DESC;
