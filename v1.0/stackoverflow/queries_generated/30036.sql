WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        COUNT(c.Id) AS CommentCount
    FROM
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE
        p.PostTypeId = 1  -- Only questions
    GROUP BY
        p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.Score
),
RecentUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        ROW_NUMBER() OVER (ORDER BY u.CreationDate DESC) AS RecentUserRank
    FROM
        Users u
    WHERE
        u.Reputation > 50  -- Only users with a reputation greater than 50
),
PopularTags AS (
    SELECT
        t.TagName,
        COUNT(pt.PostId) AS PostCount
    FROM
        Tags t
    JOIN Posts p ON t.Id = p.Tags::int[]  -- Assuming Tags can be cast to an array of integers
    GROUP BY
        t.TagName
    HAVING
        COUNT(pt.PostId) > 10  -- Popular tags having more than 10 posts
)
SELECT
    pu.UserId,
    pu.DisplayName,
    pu.Reputation,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rt.TagName,
    rt.PostCount
FROM
    RecentUsers pu
LEFT JOIN RankedPosts rp ON pu.UserId = rp.OwnerUserId
LEFT JOIN PopularTags rt ON rt.TagName = ANY (string_to_array(rp.Tags, ','))
WHERE
    pu.RecentUserRank <= 10  -- Limit to the 10 most recent eligible users
    AND (rp.UserPostRank = 1 OR rp.CommentCount > 5)  -- Either the user's latest post or posts with more than 5 comments
ORDER BY
    pu.Reputation DESC,
    rp.CreationDate DESC;
