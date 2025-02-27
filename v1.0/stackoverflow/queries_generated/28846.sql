WITH UniqueTags AS (
    SELECT DISTINCT TRIM(REGEXP_REPLACE(SUBSTRING(t.Tags FROM 2 FOR LENGTH(t.Tags) - 2), '[><]', '')) AS TagName,
           p.OwnerUserId,
           p.Id AS PostId
    FROM Posts p
    JOIN UNNEST(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) AS t(TagName)
    WHERE p.PostTypeId = 1 -- Consider only Questions
),

UserTagCounts AS (
    SELECT ut.OwnerUserId,
           ut.TagName,
           COUNT(ut.PostId) AS TagCount
    FROM UniqueTags ut
    GROUP BY ut.OwnerUserId, ut.TagName
),

UserTagsRanked AS (
    SELECT utc.OwnerUserId,
           utc.TagName,
           utc.TagCount,
           RANK() OVER (PARTITION BY utc.OwnerUserId ORDER BY utc.TagCount DESC) AS Rank
    FROM UserTagCounts utc
),

TopUserTags AS (
    SELECT utr.OwnerUserId,
           utr.TagName
    FROM UserTagsRanked utr
    WHERE utr.Rank <= 3 -- Top 3 tags for each user
),

PostsAnalysis AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.Score,
           p.ViewCount,
           p.CreationDate,
           COALESCE(sol.UserId, 0) AS OwnerUserId,
           COUNT(c.Id) AS CommentCount,
           COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVoteCount -- Only count upvotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN (SELECT DISTINCT p.OwnerUserId FROM Posts p) AS sol ON p.OwnerUserId = sol.OwnerUserId
    WHERE p.PostTypeId = 1 -- Only questions
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, sol.UserId
)

SELECT pu.Id AS UserId,
       pu.DisplayName,
       p.PostId,
       p.Title,
       p.Score,
       p.ViewCount,
       p.CommentCount,
       p.UpVoteCount,
       tt.TagName
FROM Users pu
JOIN PostsAnalysis p ON pu.Id = p.OwnerUserId
JOIN TopUserTags tt ON pu.Id = tt.OwnerUserId
WHERE pu.Reputation > 1000 -- Only consider active users with a decent reputation
ORDER BY pu.Id, p.ViewCount DESC;
