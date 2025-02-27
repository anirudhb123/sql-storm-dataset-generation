WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.TagCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankPerUser
    FROM
        Posts p
),
UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryCreationDate,
        CASE 
            WHEN ph.PostHistoryTypeId = 10 THEN cr.Name 
            ELSE NULL 
        END AS CloseReason
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id -- assuming Comment holds close reason ID for close votes
),
TopPostsByUser AS (
    SELECT
        r.PostId,
        r.Title,
        r.CreationDate,
        r.Score,
        u.DisplayName,
        ph.CloseReason
    FROM
        RankedPosts r
    JOIN
        Users u ON r.OwnerUserId = u.Id
    LEFT JOIN
        PostHistoryDetails ph ON r.PostId = ph.PostId
    WHERE
        r.RankPerUser <= 3  -- Top 3 posts per user
)
SELECT
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.TotalScore,
    us.TotalViews,
    t.Title AS TopPostTitle,
    t.CreationDate AS PostCreationDate,
    t.Score AS PostScore,
    t.CloseReason AS PostCloseReason
FROM
    UserStats us
LEFT JOIN
    TopPostsByUser t ON us.UserId = t.OwnerUserId
ORDER BY
    us.Reputation DESC,
    t.Score DESC;
