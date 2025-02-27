WITH ActiveUsers AS (
    SELECT Id, DisplayName, Reputation
    FROM Users
    WHERE LastAccessDate >= NOW() - INTERVAL '1 month'
),
RecentPosts AS (
    SELECT Posts.Id as PostId, Posts.Title, Posts.CreationDate, Posts.OwnerUserId, Posts.PostTypeId, COUNT(Comments.Id) as CommentCount
    FROM Posts
    LEFT JOIN Comments ON Posts.Id = Comments.PostId
    WHERE Posts.CreationDate >= NOW() - INTERVAL '1 month'
    GROUP BY Posts.Id, Posts.Title, Posts.CreationDate, Posts.OwnerUserId, Posts.PostTypeId
),
TopTags AS (
    SELECT Tags.TagName, COUNT(Posts.Id) as PostCount
    FROM Tags
    JOIN Posts ON Tags.Id = ANY(string_to_array(Posts.Tags, ','))
    GROUP BY Tags.TagName
    ORDER BY PostCount DESC
    LIMIT 5
),
PostDetails AS (
    SELECT RANK() OVER (PARTITION BY r.PostId ORDER BY p.Score DESC) as PostRank, 
           p.Title, 
           p.CreationDate, 
           u.DisplayName as OwnerDisplayName, 
           u.Reputation as OwnerReputation, 
           t.TagName, 
           r.CommentCount
    FROM RecentPosts p
    JOIN ActiveUsers u ON p.OwnerUserId = u.Id
    JOIN TopTags t ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN Comments r ON p.PostId = r.PostId
)
SELECT pd.PostRank, pd.Title, pd.CreationDate, pd.OwnerDisplayName, pd.OwnerReputation, pd.TagName, pd.CommentCount
FROM PostDetails pd
WHERE pd.PostRank = 1
ORDER BY pd.CreationDate DESC;
