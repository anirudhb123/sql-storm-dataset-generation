WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerName,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    WHERE
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY
        p.Id, u.DisplayName
),
ClosedPostHistory AS (
    SELECT
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate,
        STRING_AGG(DISTINCT cr.Name, ', ') AS ClosureReasons
    FROM
        PostHistory ph
    JOIN
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE
        ph.PostHistoryTypeId = 10 -- Closed
    GROUP BY
        ph.PostId
),
PostsWithClosure AS (
    SELECT
        rp.*,
        cpp.LastClosedDate,
        cpp.ClosureReasons
    FROM
        RankedPosts rp
    LEFT JOIN
        ClosedPostHistory cpp ON rp.PostId = cpp.PostId
),
TopPosts AS (
    SELECT
        *,
        COALESCE(ClosureReasons, 'No Closure') AS FinalClosureReasons,
        CASE
            WHEN LastClosedDate IS NOT NULL AND DATEDIFF(NOW(), LastClosedDate) < 30 THEN 'Recently Closed'
            ELSE 'Active'
        END AS Status
    FROM
        PostsWithClosure
    WHERE
        ScoreRank <= 5
)
SELECT
    PostId,
    Title,
    OwnerName,
    CreationDate,
    Score,
    CommentCount,
    FinalClosureReasons,
    Status
FROM
    TopPosts
ORDER BY
    Score DESC;
