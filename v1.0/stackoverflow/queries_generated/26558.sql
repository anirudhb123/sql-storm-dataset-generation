WITH PostTagCounts AS (
    SELECT
        p.Id AS PostId,
        COUNT(DISTINCT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))) ) AS TagCount
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1  -- only questions
    GROUP BY
        p.Id
),
TopUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(vt.Score, 0)) AS TotalVotes
    FROM
        Users u
    LEFT JOIN
        Posts p ON p.OwnerUserId = u.Id AND p.PostTypeId = 1 -- only questions
    LEFT JOIN
        Votes v ON v.PostId = p.Id
    LEFT JOIN
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY
        u.Id
    ORDER BY
        TotalVotes DESC
    LIMIT 10
),
OpenQuestions AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        ph.PostHistoryTypeId,
        ph.CreationDate AS LastEditDate,
        ph.UserDisplayName AS LastEditor
    FROM
        Posts p
    JOIN
        PostHistory ph ON p.Id = ph.PostId
    WHERE
        p.PostTypeId = 1 -- only questions
        AND ph.PostHistoryTypeId = 4 -- Edit Title
        AND p.ClosedDate IS NULL
    ORDER BY
        ph.CreationDate DESC
    LIMIT 5
)
SELECT
    ut.DisplayName AS TopUser,
    pt.TagCount,
    oq.Title AS OpenQuestion,
    oq.LastEditor,
    EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - oq.LastEditDate)) / 3600 AS HoursSinceLastEdit
FROM
    TopUsers ut
JOIN
    PostTagCounts pt ON pt.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ut.UserId)
JOIN
    OpenQuestions oq ON oq.Id IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ut.UserId)
ORDER BY
    pt.TagCount DESC, ut.TotalVotes DESC;

