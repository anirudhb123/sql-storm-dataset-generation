-- Performance benchmarking query for the Stack Overflow schema
WITH PostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.CreationDate >= '2023-01-01'  -- Filter for posts created in 2023
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id, u.DisplayName
)
SELECT
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ps.VoteCount,
    us.UserId,
    us.DisplayName AS PostOwner,
    us.BadgeCount,
    us.TotalUpVotes,
    us.TotalDownVotes
FROM
    PostStats ps
JOIN
    Users u ON ps.UserDisplayName = u.DisplayName  -- Assuming we can match by display name
JOIN
    UserStats us ON u.Id = us.UserId
ORDER BY
    ps.Score DESC, ps.ViewCount DESC
LIMIT 100;  -- Limit to top 100 posts for benchmarking
