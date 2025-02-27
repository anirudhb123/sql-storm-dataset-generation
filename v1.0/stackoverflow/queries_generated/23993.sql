WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(u.DisplayName, 'Deleted User') AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(COALESCE(v.VoteTypeId = 2, 0) + COALESCE(v.VoteTypeId = 3, 0)) OVER (PARTITION BY p.Id) AS TotalVotes,
        (SELECT COUNT(*) FROM Posts sub WHERE sub.ParentId = p.Id) AS AnswerCount
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.CreationDate >= DATEADD(DAY, -30, GETDATE())
),
LatestEdits AS (
    SELECT
        pe.PostId,
        MAX(pe.CreationDate) AS LastEditDate
    FROM
        PostHistory pe
    WHERE
        pe.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY
        pe.PostId
),
PostsWithBadges AS (
    SELECT
        rp.*,
        STRING_AGG(DISTINCT b.Name, ', ') AS BadgeNames
    FROM
        RankedPosts rp
    LEFT JOIN
        Badges b ON rp.OwnerUserId = b.UserId
    WHERE
        b.Date >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.OwnerDisplayName, rp.RankByScore, rp.CommentCount, rp.TotalVotes, rp.AnswerCount
)
SELECT
    pwb.PostId,
    pwb.Title,
    pwb.CreationDate,
    pwb.Score,
    pwb.ViewCount,
    pwb.OwnerDisplayName,
    pwb.RankByScore,
    pwb.CommentCount,
    pwb.AnswerCount,
    pwb.BadgeNames,
    le.LastEditDate,
    CASE
        WHEN pwb.Score > 100 THEN 'Popular'
        WHEN pwb.Score BETWEEN 50 AND 100 THEN 'Moderate'
        ELSE 'New'
    END AS PopularityCategory
FROM
    PostsWithBadges pwb
LEFT JOIN
    LatestEdits le ON pwb.PostId = le.PostId
WHERE
    pwb.AnswerCount > 0 AND
    (le.LastEditDate IS NULL OR le.LastEditDate < DATEADD(DAY, -15, GETDATE()))
ORDER BY
    pwb.Score DESC, pwb.ViewCount DESC
FETCH FIRST 50 ROWS ONLY;
