WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
CommentsSummary AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS TotalComments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS ClosedCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    ur.Reputation,
    COALESCE(ur.BadgeCount, 0) AS BadgeCount,
    COALESCE(cs.TotalComments, 0) AS TotalComments,
    COALESCE(cp.ClosedCount, 0) AS ClosedPostCount
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
LEFT JOIN 
    CommentsSummary cs ON rp.PostId = cs.PostId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 100;

WITH 
    ScoreRanking AS (
        SELECT 
            p.Id,
            p.Score,
            RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
        FROM 
            Posts p
        WHERE 
            p.PostTypeId = 1
    ),
    UserScore AS (
        SELECT 
            u.DisplayName,
            SUM(ps.Score) AS TotalScore
        FROM 
            Users u
        LEFT JOIN 
            Posts ps ON u.Id = ps.OwnerUserId
        GROUP BY 
            u.DisplayName
    )
SELECT 
    us.DisplayName,
    us.TotalScore,
    CASE 
        WHEN us.TotalScore > 1000 THEN 'Gold'
        WHEN us.TotalScore BETWEEN 500 AND 1000 THEN 'Silver'
        ELSE 'Bronze'
    END AS BadgeClass
FROM 
    UserScore us
JOIN 
    ScoreRanking sr ON us.TotalScore >= sr.Score
WHERE 
    sr.ScoreRank <= 50
ORDER BY 
    us.TotalScore DESC;
