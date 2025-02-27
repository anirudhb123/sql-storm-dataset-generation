WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        COALESCE(NULLIF(p.Score, 0), 1) AS EffectiveScore, -- Use 1 for zero scores for multiplication
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM
        Posts p
    WHERE
        p.CreationDate >= (CURRENT_DATE - INTERVAL '30 days') -- Posts created in the last 30 days
),
UserBadges AS (
    SELECT
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
),
UserActivity AS (
    SELECT
        UserId,
        SUM(COALESCE(UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(DownVotes, 0)) AS TotalDownVotes
    FROM
        Users
    GROUP BY
        UserId
),
PostsById AS (
    SELECT
        Id,
        Title,
        (SELECT STRING_AGG(DISTINCT TagName, ', ') FROM Tags t WHERE t.Id IN (
            SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'))::int)
        )) AS AssociatedTags
    FROM
        Posts p
)
SELECT
    up.Id AS UserId,
    up.DisplayName,
    rp.Title,
    rp.EffectiveScore,
    rp.CreationDate,
    u_bad.BadgeCount,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    pbi.AssociatedTags
FROM
    Users up
LEFT JOIN
    RankedPosts rp ON up.Id = rp.OwnerUserId
LEFT JOIN
    UserBadges u_bad ON up.Id = u_bad.UserId
LEFT JOIN
    UserActivity ua ON up.Id = ua.UserId
LEFT JOIN
    PostsById pbi ON pbi.Id = rp.PostId
WHERE
    rp.Rank = 1 -- Top post per user
    AND (u_bad.BadgeCount IS NULL OR u_bad.BadgeCount > 1) -- Only users with more than one badge or no badges
ORDER BY
    rp.EffectiveScore DESC,
    rp.CreationDate DESC;

-- Optionally checking for NULL logic: to check for users with no posts
SELECT
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(rp.Title, 'No Posts') AS RecentPost
FROM
    Users u
LEFT JOIN
    RankedPosts rp ON u.Id = rp.OwnerUserId
WHERE
    u.LastAccessDate < (CURRENT_TIMESTAMP - INTERVAL '90 days')
ORDER BY
    u.Reputation DESC;

In this SQL query, we implement several constructs:
1. **CTEs** (Common Table Expressions) for processing ranked posts, counting user badges, summarizing user activity, and aggregating tags.
2. **COALESCE** and **NULLIF** are used to handle potential NULL values and establish default values.
3. **Window functions** such as `ROW_NUMBER()` to rank the posts by score for each user.
4. **String aggregation** using `STRING_AGG` to fetch associated tags for each post.
5. Complex conditions including filtering users with multiple badges and checking the last access date.
6. An additional query at the end optionally checks for users who have not been active recently, displaying a default message when they have no associated posts.
