WITH PostHistoryAggregate AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        MAX(ph.UserId) AS LastEditorId,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM
        Posts p
    JOIN
        PostHistory ph ON p.Id = ph.PostId
    JOIN
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY
        p.Id
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        COUNT(DISTINCT c.Id) AS CommentsMade,
        COUNT(DISTINCT b.Id) AS BadgesReceived,
        SUM(v.BountyAmount) AS TotalBounty
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Comments c ON u.Id = c.UserId
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    LEFT JOIN
        Votes v ON u.Id = v.UserId
    GROUP BY
        u.Id
)
SELECT
    ph.PostId,
    ph.Title,
    ph.EditCount,
    ph.LastEditDate,
    ph.LastEditorId,
    ph.Tags,
    ua.UserId,
    ua.DisplayName,
    ua.PostsCreated,
    ua.CommentsMade,
    ua.BadgesReceived,
    ua.TotalBounty
FROM
    PostHistoryAggregate ph
JOIN
    UserActivity ua ON ph.LastEditorId = ua.UserId
ORDER BY
    ph.EditCount DESC, ua.PostsCreated DESC
LIMIT 10;
