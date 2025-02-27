WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.VoteCount DESC) AS RankPost,
        SUM(v.BountyAmount) OVER (PARTITION BY p.OwnerUserId) AS TotalBounties
    FROM
        Posts p
    LEFT JOIN
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  -- BountyStart and BountyClose
    WHERE
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
)

SELECT
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.VoteCount,
    CASE 
        WHEN rp.RankPost = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostRank,
    COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName,
    bp.BadgeCount
FROM
    RankedPosts rp
LEFT JOIN
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN LATERAL (
    SELECT
        COUNT(b.Id) AS BadgeCount
    FROM
        Badges b
    WHERE
        b.UserId = rp.OwnerUserId
        AND b.Class = 1  -- Only counting Gold badges
) bp ON TRUE
WHERE
    rp.RankPost <= 5  -- Top 5 posts by type
ORDER BY
    rp.PostId DESC;

-- Additionally capture certain corner cases and unusual SQL constructs
UNION ALL

SELECT
    NULL AS PostId,
    'Summary' AS Title,
    CURRENT_TIMESTAMP AS CreationDate,
    NULL AS VoteCount,
    'Aggregate Summary' AS PostRank,
    COUNT(DISTINCT u.Id) AS UniqueUserCount,
    COUNT(DISTINCT b.Id) AS TotalGoldBadges
FROM
    Users u
LEFT JOIN
    Badges b ON u.Id = b.UserId AND b.Class = 1  -- Only counting Gold badges
WHERE
    u.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
HAVING
    COUNT(DISTINCT u.Id) > 10
    AND COUNT(DISTINCT b.Id) > 5;  -- Only include users with more than 5 gold badges

This SQL query constructs a common table expression (CTE) to rank posts based on their vote count, joining votes that represent bounties. It later selects the top posts by type while counting the number of gold badges each post owner has. It also includes a separate summary section using a `UNION ALL` that aggregates user statistics over the last year, showcasing SQL constructs like `LEFT JOIN LATERAL`, `COALESCE`, window functions, and corner cases involving joins and null handling.
