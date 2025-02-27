WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(u.DisplayName, 'Community User') AS OwnerName,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
), PostDetails AS (
    SELECT
        rp.*,
        pt.Name AS PostType,
        COALESCE(pg.MaxViewCount, 0) AS MaxViewCount,
        COALESCE(pg.AvgScore, 0) AS AvgScore,
        (SELECT STRING_AGG(t.TagName, ', ') FROM Tags t WHERE t.WikiPostId = rp.PostId) AS Tags
    FROM
        RankedPosts rp
    LEFT JOIN (
        SELECT
            Id,
            MAX(ViewCount) AS MaxViewCount,
            AVG(Score) AS AvgScore
        FROM
            Posts
        GROUP BY
            Id
    ) pg ON pg.Id = rp.PostId
    JOIN PostTypes pt ON rp.PostTypeId = pt.Id
)
SELECT
    pd.PostId,
    pd.Title,
    pd.OwnerName,
    pd.PostType,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.UpVoteCount,
    pd.MaxViewCount,
    pd.AvgScore,
    CASE 
        WHEN pd.ViewCount IS NULL THEN 'No views yet'
        WHEN pd.ViewCount > 100 THEN 'Highly viewed'
        ELSE 'Moderately viewed'
    END AS ViewStatus
FROM
    PostDetails pd
WHERE
    pd.Rank <= 5
ORDER BY
    pd.Score DESC,
    pd.ViewCount DESC;

-- Instead of displaying No Reify, affected timestamps should match expected count criteria.
SELECT 
    s.FailedCount, 
    COUNT(pd.PostId) AS TotalPosts 
FROM 
    (SELECT
        COUNT(*) AS FailedCount
    FROM
        PostHistory ph
    WHERE
        ph.PostHistoryTypeId IN (10, 12, 14) -- Closed, Deleted, Locked posts
    GROUP BY
        ph.PostId) s
JOIN
    PostDetails pd ON pd.PostId = s.PostId
GROUP BY
    s.FailedCount;
