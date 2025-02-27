WITH PostTagCounts AS (
    SELECT
        p.Id AS PostId,
        COUNT(DISTINCT t.TagName) AS TagCount
    FROM
        Posts p
    JOIN
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS t(TagName) ON p.PostTypeId = 1  -- only questions
    GROUP BY
        p.Id
),
UserReputations AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT p2.Id) AS AnswerCount,
        SUM(COALESCE(b.Class, 0)) AS BadgeCount -- Summing up Badge classes to check user achievements
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1  -- Questions
    LEFT JOIN
        Posts p2 ON u.Id = p2.OwnerUserId AND p2.PostTypeId = 2  -- Answers
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id, u.Reputation
),
UserTags AS (
    SELECT
        u.Id AS UserId,
        COUNT(DISTINCT t.Id) AS UniqueTagCount
    FROM
        Users u
    JOIN
        Posts p ON u.Id = p.OwnerUserId
    JOIN
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS t(TagName) ON p.PostTypeId = 1
    GROUP BY
        u.Id
),
PostHistoryDetails AS (
    SELECT
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseReopenCount
    FROM
        PostHistory ph
    GROUP BY
        ph.PostId
)
SELECT
    u.DisplayName,
    u.Reputation,
    u.QuestionCount,
    u.AnswerCount,
    u.BadgeCount,
    ut.UniqueTagCount,
    COALESCE(ptc.TagCount, 0) AS MaxTagsPerPost,
    COALESCE(ph.LastEditDate, 'No Edits') AS LastEdited,
    ph.CloseReopenCount
FROM
    UserReputations u
LEFT JOIN
    UserTags ut ON u.UserId = ut.UserId
LEFT JOIN
    PostTagCounts ptc ON ptc.PostId = (
        SELECT
            p.Id
        FROM
            Posts p
        WHERE
            p.OwnerUserId = u.UserId
        AND
            p.PostTypeId = 1
        ORDER BY
            p.ViewCount DESC
        LIMIT 1
    )
LEFT JOIN
    PostHistoryDetails ph ON ph.PostId = (
        SELECT
            p.Id
        FROM
            Posts p
        WHERE
            p.OwnerUserId = u.UserId
        AND
            p.PostTypeId = 1
        ORDER BY
            p.CreationDate DESC
        LIMIT 1
    )
ORDER BY
    u.Reputation DESC, 
    u.QuestionCount DESC, 
    u.AnswerCount DESC;
