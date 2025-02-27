WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Body,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankPerUser
    FROM 
        Posts p
    LEFT JOIN 
        STRING_TO_ARRAY(p.Tags, '|') AS tag_array ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = TRIM(BOTH '<>' FROM UNNEST(tag_array))
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.Body, p.OwnerUserId
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoredQuestions,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeScoredQuestions,
        AVG(p.Score) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id AND p.PostTypeId = 1
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.TotalQuestions,
    us.PositiveScoredQuestions,
    us.NegativeScoredQuestions,
    us.AverageScore,
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.Tags,
    rp.CreationDate
FROM 
    UserStatistics us
JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId
WHERE 
    us.Reputation > 1000 -- Filter for users with significant reputation
AND 
    rp.RankPerUser <= 3 -- Get top 3 ranked questions per user
ORDER BY 
    us.Reputation DESC, rp.Score DESC;
