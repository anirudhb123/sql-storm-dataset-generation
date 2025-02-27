WITH RankedPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Ranking,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- Posts from the last year
    GROUP BY
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.OwnerUserId
),
UserBadges AS (
    SELECT
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
),
FilteredUsers AS (
    SELECT
        u.DisplayName,
        u.Reputation,
        u.Location,
        ub.BadgeCount,
        CASE 
            WHEN u.Reputation >= 1000 THEN 'High Reputation'
            WHEN u.Reputation >= 500 THEN 'Medium Reputation'
            ELSE 'Low Reputation'
        END AS ReputationCategory
    FROM
        Users u
    JOIN
        UserBadges ub ON u.Id = ub.UserId
    WHERE
        u.Location IS NOT NULL
)
SELECT
    up.DisplayName,
    up.ReputationCategory,
    COUNT(DISTINCT rp.Id) AS PostsCount,
    AVG(rp.Score) AS AvgScore,
    SUM(rp.ViewCount) AS TotalViews,
    SUM(rp.UpvoteCount) AS TotalUpvotes,
    SUM(rp.DownvoteCount) AS TotalDownvotes
FROM
    FilteredUsers up
JOIN
    RankedPosts rp ON up.UserId = rp.OwnerUserId
GROUP BY
    up.DisplayName, up.ReputationCategory
HAVING
    COUNT(DISTINCT rp.Id) > 5
ORDER BY
    TotalViews DESC, PostsCount DESC
LIMIT 10;

-- Performance benchmarking using an outer join example
SELECT
    u.DisplayName,
    COALESCE(SUM(v.CreationDate IS NOT NULL), 0) AS TotalVotes,
    COALESCE(SUM(c.Id IS NOT NULL), 0) AS TotalComments,
    COALESCE(SUM(CASE WHEN bh.UserId IS NOT NULL THEN 1 ELSE 0 END), 0) AS TotalBadges
FROM
    Users u
LEFT JOIN
    Votes v ON u.Id = v.UserId
LEFT JOIN
    Comments c ON u.Id = c.UserId
LEFT JOIN
    Badges bh ON u.Id = bh.UserId
GROUP BY
    u.DisplayName
HAVING
    u.Reputation > 100
ORDER BY
    TotalVotes DESC;
