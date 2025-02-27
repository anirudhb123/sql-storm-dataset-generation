WITH UserReputation AS (
    SELECT Id, Reputation,
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank,
           COUNT(*) OVER () AS TotalUsers
    FROM Users
),
PostStatistics AS (
    SELECT p.Id AS PostId, 
           p.Title, 
           p.ViewCount, 
           p.CreationDate,
           COALESCE(a.AcceptedAnswerId, -1) AS AcceptedAnswerId,
           COALESCE(c.CommentCount, 0) AS CommentCount,
           SUM(v.VoteTypeId = 2) AS UpVotes,
           SUM(v.VoteTypeId = 3) AS DownVotes,
           (SELECT COUNT(*)
            FROM Comments 
            WHERE PostId = p.Id) AS TotalComments
    FROM Posts p
    LEFT JOIN Posts a ON p.Id = a.AcceptedAnswerId 
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId) c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.ViewCount, p.CreationDate, a.AcceptedAnswerId, c.CommentCount
),
TagAnalysis AS (
    SELECT t.TagName, 
           COUNT(DISTINCT p.Id) AS PostCount,
           AVG(p.ViewCount) AS AvgViewCount,
           SUM(CASE WHEN p.CreationDate < NOW() - INTERVAL '1 year' THEN 1 ELSE 0 END) AS OldPostsCount
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
),
OuterJoinSample AS (
    SELECT u.DisplayName, 
           ur.Reputation,
           ps.PostId, 
           ps.Title, 
           ps.ViewCount, 
           ta.TagName
    FROM UserReputation ur
    LEFT JOIN PostStatistics ps ON ur.Rank = (SELECT MIN(Rank) FROM UserReputation WHERE Reputation < ur.Reputation)
    LEFT JOIN Tags ta ON ps.Title LIKE '%' || ta.TagName || '%'
    JOIN Users u ON ur.Id = u.Id
    WHERE ur.TotalUsers > 1000
)

SELECT *,
       CASE WHEN PostId IS NULL THEN 'No Published Posts' ELSE 'Has Published Posts' END AS PostStatus,
       CASE WHEN CommentCount > 5 THEN 'Highly Discussed' ELSE 'Less Discussed' END AS DiscussionLevel
FROM OuterJoinSample
WHERE (ViewCount > 100 OR TagName IS NULL)
ORDER BY ur.Reputation DESC, ps.ViewCount DESC;

WITH RecentActivity AS (
    SELECT p.Id AS PostId, 
           p.Title, 
           COUNT(DISTINCT v.UserId) AS UniqueVoters,
           COUNT(DISTINCT c.Id) AS TotalComments
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY p.Id, p.Title
),
JoinWithTags AS (
    SELECT ra.PostId, 
           ra.Title, 
           ra.UniqueVoters,
           ra.TotalComments,
           t.TagName
    FROM RecentActivity ra
    LEFT JOIN Tags t ON ra.Title LIKE '%' || t.TagName || '%'
)
SELECT PostId, Title, UniqueVoters, TotalComments, 
       ARRAY_AGG(DISTINCT TagName) AS AssociatedTags
FROM JoinWithTags
GROUP BY PostId, Title, UniqueVoters, TotalComments
HAVING COUNT(DISTINCT TagName) > 1
ORDER BY UniqueVoters DESC;

SELECT DISTINCT p.Id AS PostId, 
                CASE 
                    WHEN p.ViewCount BETWEEN 0 AND 10 THEN 'Less Viewed' 
                    WHEN p.ViewCount BETWEEN 11 AND 50 THEN 'Moderately Viewed' 
                    ELSE 'Highly Viewed' 
                END AS ViewCategory,
                array_agg(DISTINCT t.TagName) AS TagsInPost
FROM Posts p
JOIN Tags t ON p.Tags LIKE '%' || t.TagName || '%'
GROUP BY p.Id
HAVING p.CreationDate >= NOW() - INTERVAL '6 months'
ORDER BY p.ViewCount DESC;
