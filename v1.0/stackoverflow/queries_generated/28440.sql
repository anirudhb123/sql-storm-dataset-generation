WITH PopularTags AS (
    SELECT
        TRIM(UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><'))) AS TagName,
        COUNT(*) AS PostCount
    FROM
        Posts
    WHERE
        PostTypeId = 1 -- Only Questions
    GROUP BY
        TagName
    HAVING
        COUNT(*) > 10 -- Only consider tags that are used in more than 10 questions
),
TopUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.VoteTypeId = 2) AS UpVotesReceived,
        COUNT(DISTINCT p.Id) AS AnsweredQuestions
    FROM
        Users u
        INNER JOIN Posts p ON u.Id = p.OwnerUserId
        LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- Count UpVotes
    WHERE
        p.PostTypeId = 2 -- Only consider Answers
    GROUP BY
        u.Id, u.DisplayName
    ORDER BY
        UpVotesReceived DESC
    LIMIT 10
),
RecentActivity AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        COUNT(c.Id) AS CommentCount
    FROM
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.LastActivityDate
    ORDER BY
        p.LastActivityDate DESC
    LIMIT 5
)

SELECT
    t.TagName,
    t.PostCount,
    u.DisplayName AS TopUser,
    u.UpVotesReceived,
    r.Title AS RecentPostTitle,
    r.CommentCount,
    TO_CHAR(r.CreationDate, 'YYYY-MM-DD HH24:MI:SS') AS PostCreationDate,
    TO_CHAR(r.LastActivityDate, 'YYYY-MM-DD HH24:MI:SS') AS PostLastActivityDate
FROM
    PopularTags t
    JOIN TopUsers u ON u.AnsweredQuestions > 5 -- Only users who have answered more than 5 questions
    JOIN RecentActivity r ON r.Title ILIKE '%' || t.TagName || '%'
ORDER BY
    t.PostCount DESC, u.UpVotesReceived DESC
LIMIT 10;
