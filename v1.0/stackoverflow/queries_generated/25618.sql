WITH TagCounts AS (
    SELECT
        post.Id AS PostId,
        post.Tags,
        COUNT(*) AS TagCount,
        ARRAY_AGG(DISTINCT trim(unshare(unnest(string_to_array(substring(post.Tags, 2, length(post.Tags) - 2), '><'))))) AS UniqueTags
    FROM
        Posts post
    WHERE
        post.PostTypeId = 1
    GROUP BY
        post.Id, post.Tags
),
UserReputation AS (
    SELECT
        user.Id AS UserId,
        user.Reputation,
        COUNT(DISTINCT post.Id) AS PostCount
    FROM
        Users user
    INNER JOIN Posts post ON user.Id = post.OwnerUserId
    WHERE
        post.PostTypeId = 1
    GROUP BY
        user.Id, user.Reputation
),
CommentStatistics AS (
    SELECT
        post.Id AS PostId,
        COUNT(comment.Id) AS CommentCount,
        AVG(comment.Score) AS AvgCommentScore
    FROM
        Posts post
    LEFT JOIN Comments comment ON post.Id = comment.PostId
    WHERE
        post.PostTypeId = 1
    GROUP BY
        post.Id
),
EnhancedPostDetails AS (
    SELECT
        post.Id,
        post.Title,
        post.Body,
        tag.TagCount,
        user.Reputation,
        comments.CommentCount,
        comments.AvgCommentScore,
        tag.UniqueTags
    FROM
        Posts post
    LEFT JOIN TagCounts tag ON post.Id = tag.PostId
    LEFT JOIN UserReputation user ON post.OwnerUserId = user.UserId
    LEFT JOIN CommentStatistics comments ON post.Id = comments.PostId
)
SELECT
    e.Title,
    e.Body,
    e.TagCount,
    e.Reputation AS UserReputation,
    e.CommentCount,
    e.AvgCommentScore,
    e.UniqueTags,
    CASE 
        WHEN e.CommentCount > 10 THEN 'Highly Discussed'
        WHEN e.CommentCount BETWEEN 1 AND 10 THEN 'Moderately Discussed'
        ELSE 'Not Discussed'
    END AS DiscussionLevel
FROM
    EnhancedPostDetails e
WHERE
    e.Reputation >= 1000
ORDER BY
    e.TagCount DESC,
    e.CommentCount DESC;
