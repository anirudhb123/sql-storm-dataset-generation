WITH TagDetails AS (
    SELECT
        p.Id AS PostId,
        STRING_AGG(T.TagName, ', ') AS Tags,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT v.Id) AS TotalVotes,
        MAX(b.Date) AS LastBadgeDate
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    LEFT JOIN
        Badges b ON p.OwnerUserId = b.UserId
    WHERE
        p.PostTypeId = 1 -- Only questions
    GROUP BY
        p.Id
),
PostActivity AS (
    SELECT
        ps.Id AS PostId,
        ps.Title,
        ps.CreationDate,
        ps.OwnerUserId,
        COALESCE(h.ActionCount, 0) AS ActionCount
    FROM
        Posts ps
    LEFT JOIN (
        SELECT
            PostId,
            COUNT(*) AS ActionCount
        FROM
            PostHistory
        WHERE
            CreationDate > NOW() - INTERVAL '1 year'
        GROUP BY
            PostId
    ) h ON ps.Id = h.PostId
    WHERE
        ps.PostTypeId = 1
),
UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
)
SELECT
    ta.PostId,
    ta.Tags,
    pa.Title,
    pa.CreationDate,
    pa.ActionCount,
    ur.Reputation,
    ur.BadgeCount,
    ta.TotalComments,
    ta.TotalVotes,
    ta.LastBadgeDate
FROM
    TagDetails ta
JOIN
    PostActivity pa ON ta.PostId = pa.PostId
JOIN
    UserReputation ur ON pa.OwnerUserId = ur.UserId
ORDER BY
    ta.TotalVotes DESC,
    ta.LastBadgeDate DESC;
