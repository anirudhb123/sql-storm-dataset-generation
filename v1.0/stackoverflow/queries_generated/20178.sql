WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days' 
        AND p.PostTypeId = 1  -- considering only questions
    GROUP BY 
        p.Id
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        COUNT(ph.Id) AS HistoryCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        (SELECT AVG(Score) FROM Posts WHERE OwnerUserId = u.Id) AS AvgPostScore
    FROM 
        Users u
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.ScoreRank,
    COALESCE(uh.UserId, 0) AS UserIdWithHighestReputation,
    COALESCE(u.Reputation, 0) AS UserReputation,
    COALESCE(u.AvgPostScore, 0) AS UserAvgPostScore,
    phs.HistoryTypes,
    phs.HistoryCount,
    CASE 
        WHEN rp.HighestBadgeClass IS NULL THEN 'No Badge'
        ELSE CASE 
            WHEN rp.HighestBadgeClass = 1 THEN 'Gold Badge'
            WHEN rp.HighestBadgeClass = 2 THEN 'Silver Badge'
            WHEN rp.HighestBadgeClass = 3 THEN 'Bronze Badge'
            END
    END AS BadgeDescription
FROM 
    RankedPosts rp
LEFT JOIN 
    UserReputation u ON u.UserId = rp.OwnerUserId
LEFT JOIN 
    PostHistorySummary phs ON phs.PostId = rp.PostId
LEFT JOIN (
    SELECT 
        OwnerUserId, 
        RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        Users 
) uh ON rp.OwnerUserId = uh.OwnerUserId AND uh.Rank = 1
WHERE 
    rp.ScoreRank <= 5  -- top 5 posts per user based on score
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
LIMIT 100;
