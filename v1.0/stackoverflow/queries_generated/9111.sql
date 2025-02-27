WITH UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON v.PostId = p.Id
    LEFT JOIN Badges b ON b.UserId = u.Id
    GROUP BY
        u.Id, u.DisplayName
), 
PostDetails AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - p.CreationDate)) AS PostAgeInSeconds,
        CASE
            WHEN p.ClosedDate IS NOT NULL THEN 1
            ELSE 0
        END AS IsClosed,
        ARRAY_AGG(DISTINCT tag.TagName) AS Tags
    FROM
        Posts p
    LEFT JOIN LATERAL unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag ON TRUE
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.ClosedDate
)
SELECT
    ua.DisplayName,
    ua.PostCount,
    ua.QuestionCount,
    ua.AnswerCount,
    ua.UpVotes,
    ua.DownVotes,
    ua.BadgeCount,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.PostAgeInSeconds,
    pd.IsClosed,
    pd.Tags
FROM
    UserActivity ua
JOIN
    PostDetails pd ON ua.UserId = pd.PostId
WHERE
    ua.PostCount > 5
ORDER BY
    ua.UpVotes DESC, ua.BadgeCount DESC, pd.PostAgeInSeconds ASC
LIMIT 100;
