WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsArray
    FROM
        Posts p
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN LATERAL (
            SELECT
                unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName
        ) t ON TRUE
    WHERE
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY
        p.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT
        ph.PostId,
        MIN(ph.CreationDate) AS FirstClosedDate
    FROM
        PostHistory ph
    WHERE
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY
        ph.PostId
),
JoinedPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        rp.ScoreRank,
        rp.CommentCount,
        rp.TagsArray,
        COALESCE(cp.FirstClosedDate, 'No Closure') AS ClosedStatus
    FROM
        RankedPosts rp
        LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT
    jp.PostId,
    jp.Title,
    jp.CreationDate,
    jp.Score,
    jp.OwnerDisplayName,
    jp.ScoreRank,
    CASE
        WHEN jp.ClosedStatus = 'No Closure' THEN 'Active'
        ELSE 'Closed on ' || TO_CHAR(jp.ClosedStatus, 'YYYY-MM-DD HH24:MI:SS')
    END AS PostStatus,
    jp.CommentCount,
    jp.TagsArray
FROM
    JoinedPosts jp
WHERE
    jp.ScoreRank <= 5 -- top 5 posts in their respective types
ORDER BY
    jp.Score DESC, jp.CreationDate DESC
LIMIT 10;

-- Additional Stats with an eye for bizarrely and obscure semantics
UNION ALL

SELECT
    NULL AS PostId,
    'Total Users With Badges' AS Title,
    NULL AS CreationDate,
    COUNT(DISTINCT b.UserId) AS Score,
    NULL AS OwnerDisplayName,
    NULL AS ScoreRank,
    NULL AS CommentCount,
    NULL AS TagsArray,
    'Users holding at least one badge' AS PostStatus
FROM
    Badges b
WHERE
    b.Date >= DATE_TRUNC('year', NOW()) -- badges acquired this year
HAVING
    COUNT(DISTINCT b.Id) > 1; -- more than one badge

-- Note: This segment will return NULL for primary fields to create a cohesive result set structure.
