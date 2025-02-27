
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        GROUP_CONCAT(DISTINCT ct.Name) AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ct ON ph.Comment = CAST(ct.Id AS CHAR)
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        SUM(IF(b.Class = 1, 1, 0)) AS GoldCount,
        SUM(IF(b.Class = 2, 1, 0)) AS SilverCount,
        SUM(IF(b.Class = 3, 1, 0)) AS BronzeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    rp.Id AS PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.UpVotes,
    rp.DownVotes,
    rp.ScoreRank,
    cp.CloseCount,
    cp.CloseReasons,
    ub.GoldCount,
    ub.SilverCount,
    ub.BronzeCount
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.PostId
LEFT JOIN 
    Users u ON rp.Id = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    (rp.Score > 10 OR cp.CloseCount IS NOT NULL)
    AND rp.CreationDate > NOW() - INTERVAL 90 DAY
ORDER BY 
    rp.ScoreRank, rp.ViewCount DESC
LIMIT 100;
