WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Author,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        COALESCE(vv.UpVotes, 0) - COALESCE(vv.DownVotes, 0) AS Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COALESCE(vv.UpVotes, 0) - COALESCE(vv.DownVotes, 0) DESC) AS PostRank
    FROM
        Posts p
    LEFT JOIN 
        (SELECT
            PostId,
            COUNT(*) AS CommentCount
         FROM
            Comments
         GROUP BY
            PostId) pc ON p.Id = pc.PostId
    LEFT JOIN 
        (SELECT
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
         FROM
            Votes
         GROUP BY
            PostId) vv ON p.Id = vv.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Focus on recent posts
)
SELECT
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Author,
    rp.CommentCount,
    rp.Score
FROM
    RankedPosts rp
WHERE
    (rp.PostRank <= 5 OR rp.CommentCount > 10)  -- Top 5 posts by type or those with more than 10 comments
ORDER BY
    rp.Score DESC;

-- Analytical query for top badge earners
WITH UserBadges AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
)
SELECT
    ub.DisplayName,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges
FROM
    UserBadges ub
WHERE
    ub.BadgeCount > 0
ORDER BY
    ub.BadgeCount DESC
LIMIT 10;

-- Recursive CTE for tracking post edits and their histories
WITH RECURSIVE PostEditHistory AS (
    SELECT
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        1 AS Level
    FROM
        PostHistory ph
    WHERE
        ph.PostHistoryTypeId IN (4, 5, 6)  -- Edit Title, Body, Tags
    UNION ALL
    SELECT
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        pe.Level + 1
    FROM
        PostHistory ph
    JOIN
        PostEditHistory pe ON ph.PostId = pe.PostId
    WHERE
        ph.CreationDate < pe.CreationDate  -- Only select entries older than the current recursive level
)
SELECT
    pe.PostId,
    COUNT(*) AS EditCount,
    MAX(pe.CreationDate) AS LastEditDate
FROM
    PostEditHistory pe
GROUP BY
    pe.PostId
HAVING
    COUNT(*) > 3  -- Filter posts that have been edited more than 3 times
ORDER BY
    LastEditDate DESC;

-- Final complex aggregation on votes with outer joins
SELECT 
    p.Id AS PostId,
    p.Title,
    COALESCE(vv.UpVotes, 0) AS UpVotes,
    COALESCE(vv.DownVotes, 0) AS DownVotes,
    COALESCE(vv.UpVotes, 0) - COALESCE(vv.DownVotes, 0) AS NetVotes,
    (CASE 
        WHEN COALESCE(vv.UpVotes, 0) > COALESCE(vv.DownVotes, 0) THEN 'Positive'
        WHEN COALESCE(vv.UpVotes, 0) < COALESCE(vv.DownVotes, 0) THEN 'Negative'
        ELSE 'Neutral'
     END) AS VoteSentiment
FROM 
    Posts p
LEFT JOIN 
    (SELECT
        PostId,

