WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM
        Posts p
    WHERE
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
),
PostMetrics AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        c.CommentCount,
        COALESCE(v.UpVoteCount, 0) AS UpVotes,
        COALESCE(v.DownVoteCount, 0) AS DownVotes,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM
        RankedPosts rp
    LEFT JOIN (
        SELECT
            PostId,
            COUNT(*) AS CommentCount
        FROM
            Comments
        GROUP BY
            PostId
    ) c ON rp.PostId = c.PostId
    LEFT JOIN (
        SELECT
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
        FROM
            Votes
        GROUP BY
            PostId
    ) v ON rp.PostId = v.PostId
    LEFT JOIN (
        SELECT
            UserId,
            COUNT(*) AS BadgeCount
        FROM
            Badges
        GROUP BY
            UserId
    ) b ON b.UserId IN (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
)
SELECT
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.Score,
    pm.ViewCount,
    pm.CommentCount,
    pm.UpVotes,
    pm.DownVotes,
    pm.BadgeCount
FROM
    PostMetrics pm
WHERE
    pm.Rank <= 5
ORDER BY
    pm.Score DESC;

WITH RecursivePostLinks AS (
    SELECT
        pl.Id,
        pl.PostId,
        pl.RelatedPostId,
        1 AS Level
    FROM
        PostLinks pl
    WHERE
        pl.PostId IN (SELECT PostId FROM PostMetrics)

    UNION ALL

    SELECT
        pl.Id,
        pl.PostId,
        pl.RelatedPostId,
        rpl.Level + 1
    FROM
        PostLinks pl
    INNER JOIN RecursivePostLinks rpl ON pl.PostId = rpl.RelatedPostId
)
SELECT
    p.Id AS OriginalPostId,
    rp.Title AS RelatedPostTitle,
    COUNT(rpl.Id) AS LinkCount,
    MAX(rpl.Level) AS MaxLinkLevel
FROM
    Posts p
LEFT JOIN RecursivePostLinks rpl ON p.Id = rpl.PostId
LEFT JOIN Posts rp ON rpl.RelatedPostId = rp.Id
GROUP BY
    p.Id,
    rp.Title
HAVING
    COUNT(rpl.Id) > 1
ORDER BY
    LinkCount DESC;
