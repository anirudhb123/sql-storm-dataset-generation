WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS ViewRank,
        p.CreationDate,
        p.LastActivityDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM
        Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.LastActivityDate, p.OwnerUserId
),
ClosedPosts AS (
    SELECT
        p.Id AS PostId,
        ph C.comment AS CloseComment,
        ph.CreationDate AS ClosedDate,
        u.DisplayName AS ClosedBy
    FROM
        PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    JOIN Users u ON ph.UserId = u.Id
    WHERE
        ph.PostHistoryTypeId = 10 AND ph.Comment IS NOT NULL
),
TopUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(COALESCE(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END, 0)) AS ClosedPostsCount
    FROM
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY
        u.Id, u.DisplayName
)
SELECT
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Upvotes,
    rp.Downvotes,
    cp.ClosedComment,
    cp.ClosedDate,
    cp.ClosedBy,
    tu.DisplayName AS TopUser,
    tu.PostsCount,
    tu.ClosedPostsCount
FROM
    RankedPosts rp
LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
JOIN TopUsers tu ON rp.ViewCount > 100 AND tu.PostsCount > 5
WHERE
    rp.ViewRank = 1
    AND rp.LastActivityDate < NOW() - INTERVAL '30 days'
ORDER BY
    rp.ViewCount DESC, tu.ClosedPostsCount DESC
LIMIT 50;

-- With this query, you'll identify trending poorly-performing posts (i.e., high views but closed) over the last 30 days, 
-- along with user engagement metrics like upvotes and downvotes with interesting relationships between users and post closures.
