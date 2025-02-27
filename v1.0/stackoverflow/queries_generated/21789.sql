WITH UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.Reputation
),
ClosedPosts AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS ClosedPostCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10 -- post closed
    GROUP BY ph.UserId
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(Tags, ',')) AS Tag
    FROM Posts
    WHERE PostTypeId = 1 -- Questions only
),
TagCounts AS (
    SELECT 
        Tag,
        COUNT(*) AS TagUsage
    FROM PopularTags
    GROUP BY Tag
    HAVING COUNT(*) > 5
),
RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        ur.Reputation,
        COALESCE(cp.ClosedPostCount, 0) AS ClosedPostCount,
        ROW_NUMBER() OVER (ORDER BY ur.Reputation DESC, ur.Upvotes - ur.Downvotes DESC) AS UserRank
    FROM UserReputation ur
    LEFT JOIN ClosedPosts cp ON ur.UserId = cp.UserId
    WHERE ur.PostCount > 5
)
SELECT 
    ru.UserId,
    ru.Reputation,
    ru.ClosedPostCount,
    tg.Tag AS PopularTag,
    tg.TagUsage
FROM RankedUsers ru
LEFT JOIN TagCounts tg ON tg.Tag IN (
    SELECT Tag 
    FROM PopularTags p
    WHERE p.Tag IS NOT NULL
)
WHERE ru.UserRank <= 20
ORDER BY ru.UserRank,
    COALESCE(tg.TagUsage, 0) DESC;

WITH RECURSIVE TagHierarchy AS (
    SELECT 
        TagName,
        1 AS Level
    FROM Tags
    WHERE IsModeratorOnly = 1
    UNION ALL
    SELECT 
        CONCAT(th.TagName, ' > ', t.TagName),
        th.Level + 1
    FROM TagHierarchy th
    JOIN Tags t ON th.TagName != t.TagName
    WHERE t.IsRequired = 0 AND th.Level < 5
)
SELECT 
    TagName,
    Level,
    COUNT(*) AS TagCount
FROM TagHierarchy
GROUP BY TagName, Level
HAVING COUNT(*) > 2
ORDER BY Level DESC;

This query is designed to perform a comprehensive analysis by employing a series of CTEs to compute user reputation metrics, count closed posts, identify popular tags, rank users, and build a recursive hierarchy of tags while ensuring intricate SQL constructs like outer joins, aggregates, and window functions are effectively utilized.
