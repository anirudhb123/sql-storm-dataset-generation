WITH PopularTags AS (
    SELECT Tags.TagName, COUNT(Posts.Id) AS PostCount
    FROM Tags
    JOIN Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '><')::int[])
    GROUP BY Tags.TagName
    HAVING COUNT(Posts.Id) > 10
),
ActiveUsers AS (
    SELECT Users.Id, Users.DisplayName, SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes, 
           SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Users
    JOIN Votes ON Users.Id = Votes.UserId
    WHERE Users.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY Users.Id, Users.DisplayName
    HAVING SUM(Votes.VoteTypeId IN (2, 3)) > 5
),
PostStats AS (
    SELECT Posts.Id, Posts.Title, Posts.Score, Posts.CreationDate, 
           COALESCE(CAST(Posts.LastActivityDate AS DATE), CAST(Posts.CreationDate AS DATE)) AS LastActiveDate,
           ARRAY_AGG(DISTINCT Tags.TagName) AS Tags
    FROM Posts
    LEFT JOIN Tags ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '><')::int[])
    WHERE Posts.CreationDate > NOW() - INTERVAL '6 months'
    GROUP BY Posts.Id, Posts.Title, Posts.Score, Posts.CreationDate, Posts.LastActivityDate
),
FinalMetrics AS (
    SELECT ps.Title, ps.Score, ps.LastActiveDate, 
           ARRAY_AGG(DISTINCT pt.Name) AS PostType, 
           t.TagName AS PopularTag, 
           au.DisplayName AS ActiveUser, 
           au.Upvotes, au.Downvotes
    FROM PostStats ps
    JOIN PopularTags t ON ps.Tags && ARRAY[t.TagName]
    JOIN PostTypes pt ON pt.Id = (SELECT PostTypeId FROM Posts WHERE Id = ps.Id)
    JOIN ActiveUsers au ON au.Upvotes + au.Downvotes > 15
    GROUP BY ps.Title, ps.Score, ps.LastActiveDate, t.TagName, au.DisplayName, au.Upvotes, au.Downvotes
)
SELECT * 
FROM FinalMetrics
ORDER BY Score DESC, LastActiveDate DESC;
