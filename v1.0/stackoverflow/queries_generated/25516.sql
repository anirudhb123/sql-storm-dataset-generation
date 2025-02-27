WITH PostTags AS (
    SELECT
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS Tag
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1  -- Only questions
),
MostActiveUsers AS (
    SELECT
        u.Id AS UserId,
        COUNT(v.Id) AS VoteCount
    FROM
        Votes v
    JOIN Users u ON u.Id = v.UserId
    GROUP BY
        u.Id
    ORDER BY
        VoteCount DESC
    LIMIT 10
),
PostContent AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        ARRAY_AGG(DISTINCT pt.Tag) AS Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName
    FROM
        Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN PostTags pt ON pt.PostId = p.Id
    WHERE
        p.ViewCount > 1000  -- Popular posts
    GROUP BY
        p.Id, u.DisplayName
),
PostHistorySummary AS (
    SELECT
        ph.PostId,
        MIN(ph.CreationDate) AS FirstEditDate,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM
        PostHistory ph
    GROUP BY
        ph.PostId
    HAVING
        COUNT(ph.Id) > 1  -- Only posts that have been edited more than once
),
UserBadges AS (
    SELECT
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM
        Users u
    LEFT JOIN Badges b ON b.UserId = u.Id
    GROUP BY
        u.Id
)
SELECT
    pc.PostId,
    pc.Title,
    pc.OwnerDisplayName,
    pb.EditCount,
    pb.FirstEditDate,
    pb.LastEditDate,
    ARRAY_AGG(DISTINCT pt.Tag) AS Tags,
    ub.BadgeCount,
    mau.VoteCount
FROM
    PostContent pc
JOIN PostHistorySummary pb ON pb.PostId = pc.PostId
JOIN Users u ON u.DisplayName = pc.OwnerDisplayName
LEFT JOIN UserBadges ub ON ub.UserId = u.Id
LEFT JOIN MostActiveUsers mau ON mau.UserId = u.Id
GROUP BY
    pc.PostId, pc.Title, pc.OwnerDisplayName, pb.EditCount, pb.FirstEditDate, pb.LastEditDate, ub.BadgeCount, mau.VoteCount
ORDER BY
    pc.CreationDate DESC
LIMIT 50;  -- Limit to the most recent 50 posts
