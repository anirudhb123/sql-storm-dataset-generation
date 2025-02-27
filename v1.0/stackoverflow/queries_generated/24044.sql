WITH RankedPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM
        Posts p
    WHERE
        p.CreationDate > NOW() - INTERVAL '1 year'
),
VoteAggregates AS (
    SELECT
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM
        Votes v
    GROUP BY
        v.PostId
),
CommentedPosts AS (
    SELECT
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM
        Comments c
    WHERE
        c.CreationDate > NOW() - INTERVAL '6 months'
    GROUP BY
        c.PostId
),
ClosedPosts AS (
    SELECT
        ph.PostId,
        COUNT(*) AS CloseCount,
        MAX(ph.CreationDate) AS LastClosed
    FROM
        PostHistory ph
    WHERE
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY
        ph.PostId
)
SELECT
    rp.Title,
    rp.CreationDate,
    COALESCE(va.UpVotes, 0) AS UpVotes,
    COALESCE(va.DownVotes, 0) AS DownVotes,
    COALESCE(cp.CommentCount, 0) AS CommentCount,
    COALESCE(cl.CloseCount, 0) AS CloseCount,
    COALESCE(cl.LastClosed, 'Never Closed') AS LastClosed,
    CASE 
        WHEN COALESCE(cp.CommentCount, 0) > 5 THEN 'Highly Engaged'
        ELSE 'Less Engaged'
    END AS EngagementLevel,
    CASE 
        WHEN cl.LastClosed IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS ClosureStatus,
    CASE 
        WHEN rp.Score > 0 AND COALESCE(cl.LastClosed, 0) = 0 THEN 'Potential Hot Topic'
        ELSE 'Normal'
    END AS TopicPotential
FROM
    RankedPosts rp
LEFT JOIN
    VoteAggregates va ON rp.Id = va.PostId
LEFT JOIN
    CommentedPosts cp ON rp.Id = cp.PostId
LEFT JOIN
    ClosedPosts cl ON rp.Id = cl.PostId
WHERE
    rp.Rank = 1
ORDER BY
    rp.ViewCount DESC
LIMIT 50;

This query gathers data concerning posts over the last year, including their engagement metrics, vote details, comments, and closure status. It utilizes Common Table Expressions (CTEs) to structure the data, correlated subqueries to introspect specific metrics, and conditional logic to categorize and rank posts in unique ways, providing insights into their status and potential issues, all while ensuring to account for various null logic cases.
