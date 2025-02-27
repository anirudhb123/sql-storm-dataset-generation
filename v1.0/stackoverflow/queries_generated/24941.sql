WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),
MaxScorePost AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score 
    FROM 
        RankedPosts 
    WHERE 
        PostRank = 1
),
OverallStats AS (
    SELECT 
        u.Id AS UserId,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        MAX(p.CreationDate) AS LatestPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation IS NOT NULL 
        AND u.CreationDate < NOW() - INTERVAL '1 year'
    GROUP BY 
        u.Id
)
SELECT 
    os.UserId,
    os.TotalScore,
    os.BadgeCount,
    os.VoteCount,
    mp.Title AS LatestHighScoringPost,
    mp.CreationDate AS LatestHighScoringPostDate
FROM 
    OverallStats os
LEFT JOIN 
    MaxScorePost mp ON os.UserId IN (
        SELECT UserId 
        FROM Posts 
        WHERE Id = mp.PostId
    )
WHERE 
    os.TotalScore > (SELECT AVG(TotalScore) FROM OverallStats)
    AND os.BadgeCount > 1
    AND (os.LatestPostDate IS NOT NULL OR os.LatestPostDate < NOW() - INTERVAL '30 days')
ORDER BY 
    os.TotalScore DESC
LIMIT 10;

-- Additional complexity with conditionals
UNION ALL

SELECT 
    u.Id AS UserId,
    SUM(CASE WHEN p.Score IS NULL THEN 0 ELSE p.Score END) AS TotalScore,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    NULL AS LatestHighScoringPost,
    NULL AS LatestHighScoringPostDate
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    u.Reputation BETWEEN 0 AND 50
GROUP BY 
    u.Id
HAVING 
    COUNT(DISTINCT p.Id) = 0
ORDER BY 
    TotalScore DESC
LIMIT 5;
