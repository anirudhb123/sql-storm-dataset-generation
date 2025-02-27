WITH TaggedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        STRING_AGG(t.TagName, ', ') AS TagsList
    FROM
        Posts p
    LEFT JOIN
        LATERAL STRING_TO_ARRAY(p.Tags, ',') AS tag ON true
    JOIN
        Tags t ON t.TagName = TRIM(BOTH '<>' FROM tag)
    GROUP BY
        p.Id, p.Title
),
UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM
        Users u
),
ClosedPosts AS (
    SELECT
        ph.PostId,
        ph.CreationDate,
        STRING_AGG(DISTINCT c.Text, '; ') AS ClosingComments
    FROM
        PostHistory ph
    JOIN
        CloseReasonTypes crt ON ph.Comment::int = crt.Id
    LEFT JOIN
        Comments c ON c.PostId = ph.PostId
    WHERE
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY
        ph.PostId, ph.CreationDate
)
SELECT
    tp.PostId,
    tp.Title,
    tp.TagsList,
    up.Reputation,
    up.ReputationRank,
    cp.CreationDate AS ClosedDate,
    cp.ClosingComments
FROM
    TaggedPosts tp
JOIN
    UserReputation up ON tp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = up.UserId)
LEFT JOIN
    ClosedPosts cp ON tp.PostId = cp.PostId
WHERE
    up.Reputation > 1000
ORDER BY
    up.Reputation DESC, tp.Title;
