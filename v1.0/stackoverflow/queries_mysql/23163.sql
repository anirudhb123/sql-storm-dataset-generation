
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS PopularityRank,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COUNT(c.Id) AS CommentCount,
        GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') AS Tags
    FROM
        Posts AS p
    LEFT JOIN
        Votes AS v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    LEFT JOIN
        Comments AS c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT
            p.Id,
            TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '<', -1)) AS TagName
        FROM
            Posts AS p
        INNER JOIN (
            SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
            UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
            UNION ALL SELECT 9 UNION ALL SELECT 10
        ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1
    ) AS t ON p.Id = t.Id
    WHERE
        p.CreationDate >= '2023-10-01 12:34:56'
    GROUP BY
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.PostTypeId
),
FilteredPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Tags,
        rp.PopularityRank,
        rp.VoteCount,
        rp.CommentCount
    FROM
        RankedPosts AS rp
    WHERE
        rp.PopularityRank <= 5
),
PostActivity AS (
    SELECT
        ph.PostId,
        ph.PostHistoryTypeId,
        MIN(ph.CreationDate) AS FirstActivityDate,
        MAX(ph.CreationDate) AS LastActivityDate
    FROM
        PostHistory AS ph
    GROUP BY
        ph.PostId, ph.PostHistoryTypeId
),
PostStats AS (
    SELECT
        fp.PostId,
        fp.Title,
        fp.ViewCount,
        fp.Tags,
        fp.VoteCount,
        fp.CommentCount,
        pa.FirstActivityDate,
        pa.LastActivityDate,
        TIMESTAMPDIFF(SECOND, pa.FirstActivityDate, pa.LastActivityDate) AS ActivityDuration
    FROM
        FilteredPosts AS fp
    LEFT JOIN
        PostActivity AS pa ON fp.PostId = pa.PostId
)
SELECT
    ps.*,
    CASE
        WHEN ps.ViewCount IS NULL THEN 'No Views'
        ELSE CONCAT('View Count: ', ps.ViewCount)
    END AS ViewCountReport,
    CASE
        WHEN ps.CommentCount = 0 THEN 'No Comments'
        ELSE CAST(ps.CommentCount AS CHAR)
    END AS CommentActivityReport,
    COALESCE(ps.Tags, 'No Tags') AS TagsSummary,
    CASE
        WHEN ps.VoteCount > 10 THEN 'Highly Voted'
        WHEN ps.VoteCount IS NULL THEN 'No Votes'
        ELSE 'Moderately Voted'
    END AS VoteStatus,
    CASE
        WHEN ps.ActivityDuration IS NULL THEN 'No Activity'
        WHEN ps.ActivityDuration < 3600 THEN 'Active (<1 hour)'
        WHEN ps.ActivityDuration < 86400 THEN 'Recently Active (<24 hours)'
        ELSE 'Stale'
    END AS ActivityStatus
FROM
    PostStats AS ps
WHERE
    EXISTS (
        SELECT 1
        FROM Users AS u
        WHERE u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = ps.PostId) 
          AND u.Reputation > 500 
    )
ORDER BY
    ps.VoteCount DESC,
    ps.ViewCount DESC;
