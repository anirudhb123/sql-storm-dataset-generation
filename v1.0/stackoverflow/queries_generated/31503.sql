WITH RecursiveTagCounts AS (
    SELECT TagName, COUNT(PostId) AS TagCount
    FROM Tags 
    JOIN Posts ON Tags.Id = Posts.Tags
    GROUP BY TagName

    UNION ALL

    SELECT Tags.TagName, COUNT(PostLinks.RelatedPostId)
    FROM Tags
    JOIN PostLinks ON Tags.Id = PostLinks.RelatedPostId
    WHERE PostLinks.LinkTypeId = 1
    GROUP BY Tags.TagName
),
UserReputation AS (
    SELECT 
        Users.Id AS UserId,
        Users.Reputation,
        RANK() OVER (ORDER BY Users.Reputation DESC) AS ReputationRank
    FROM Users
),
TopUsers AS (
    SELECT UserId, Reputation, ReputationRank
    FROM UserReputation
    WHERE ReputationRank <= 10
),
PostStats AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.ViewCount,
        Posts.Score,
        COALESCE(COUNT(Votes.Id) FILTER (WHERE VoteTypeId = 2), 0) AS Upvotes,
        COALESCE(COUNT(Votes.Id) FILTER (WHERE VoteTypeId = 3), 0) AS Downvotes,
        COUNT(Comments.Id) AS CommentCount
    FROM Posts
    LEFT JOIN Votes ON Posts.Id = Votes.PostId
    LEFT JOIN Comments ON Posts.Id = Comments.PostId
    GROUP BY Posts.Id
),
ClosedPosts AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        PH.CreationDate AS ClosedDate,
        PH.Comment
    FROM PostHistory PH
    JOIN Posts ON PH.PostId = Posts.Id
    WHERE PH.PostHistoryTypeId = 10
),
FinalResults AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.ViewCount,
        ps.Score,
        ps.Upvotes,
        ps.Downvotes,
        ps.CommentCount,
        CASE 
            WHEN cp.ClosedDate IS NOT NULL THEN 'Closed'
            ELSE 'Active'
        END AS PostStatus,
        COALESCE(rt.TagCount, 0) AS RelatedTagCount
    FROM PostStats ps
    LEFT JOIN ClosedPosts cp ON ps.PostId = cp.PostId
    LEFT JOIN RecursiveTagCounts rt ON rt.TagName = ANY(string_to_array(ps.Title, ' ')) 
)
SELECT 
    fu.UserId,
    fu.Reputation,
    fr.PostId,
    fr.Title,
    fr.ViewCount,
    fr.Score,
    fr.Upvotes,
    fr.Downvotes,
    fr.CommentCount,
    fr.PostStatus,
    fr.RelatedTagCount
FROM FinalResults fr
JOIN TopUsers fu ON fr.Score > 5 
ORDER BY fu.Reputation DESC, fr.ViewCount DESC
LIMIT 100;
