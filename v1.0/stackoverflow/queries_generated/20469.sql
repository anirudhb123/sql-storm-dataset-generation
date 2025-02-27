WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankInType
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasonNames
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON cr.Id = CAST(ph.Comment AS int)
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.UpVotes,
    rp.DownVotes,
    COALESCE(cr.CloseReasonNames, 'No close reasons') AS CloseReasons,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges
FROM 
    RankedPosts rp
LEFT JOIN 
    CloseReasons cr ON rp.PostId = cr.PostId
LEFT JOIN 
    Users u ON u.Id = rp.PostId    -- Assuming PostId relates to a user's Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    rp.RankInType <= 5
    AND (rp.UpVotes - rp.DownVotes) >= 10
    OR rp.CreationDate > NOW() - INTERVAL '1 month'
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate ASC
LIMIT 100;

In this elaborate SQL query:

- The first Common Table Expression (CTE) `RankedPosts` computes the ranking of posts by their score, calculating up and down votes for each post.
- The second CTE `CloseReasons` aggregates the names of close reasons for posts that have been closed.
- The third CTE `UserBadges` counts the number of badges users hold, differentiated by class.
- The main SELECT combines results from these CTEs, applying complex filtering logic that involves combined conditions with `AND` and `OR` operators.
- The results are ordered by score descending, with conditions applied to include specific ranks and vote differences, limiting the output to the top 100 entries.

This query covers diverse SQL constructs and corner cases, making it suitable for performance benchmarking.
