WITH TagCounts AS (
    SELECT
        TagName,
        COUNT(*) AS PostCount
    FROM
        Tags
    GROUP BY
        TagName
),
TopTags AS (
    SELECT
        TagName
    FROM
        TagCounts
    WHERE
        PostCount > 50 -- Only considering tags with more than 50 posts
),
PostsWithTopTags AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.OwnerDisplayName,
        STRING_AGG(t.TagName, ', ') AS TagList
    FROM
        Posts p
    JOIN
        unnest(string_to_array(p.Tags, '><')) AS tag ON tag IS NOT NULL
    JOIN
        TopTags tt ON tt.TagName = tag
    GROUP BY
        p.Id
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM
        Users u
    LEFT JOIN
        Posts p ON p.OwnerUserId = u.Id AND p.PostTypeId = 1 -- Only questions
    LEFT JOIN
        Comments c ON c.UserId = u.Id
    LEFT JOIN
        Badges b ON b.UserId = u.Id
    GROUP BY
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT
        ua.UserId,
        ua.DisplayName,
        ua.QuestionCount,
        ua.CommentCount,
        ua.BadgeCount,
        RANK() OVER (ORDER BY ua.QuestionCount DESC) AS Rank
    FROM
        UserActivity ua
    WHERE
        ua.QuestionCount > 10 -- Only considering users with more than 10 questions
)
SELECT
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    p.OwnerDisplayName AS PostOwner,
    u.DisplayName AS UserDisplayName,
    u.QuestionCount,
    u.CommentCount,
    u.BadgeCount,
    p.TagList
FROM
    PostsWithTopTags p
JOIN
    TopUsers u ON u.UserId = p.OwnerUserId
WHERE
    p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'  -- Only posts from the last year
ORDER BY
    u.QuestionCount DESC, p.CreationDate DESC
LIMIT 100;  -- Limit to 100 results
