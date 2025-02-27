WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.AnswerCount, 
        p.CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        u.Reputation > 1000 AND p.PostTypeId = 1 -- Filtering for high-reputation users' questions
),
TopPostStats AS (
    SELECT 
        rp.OwnerUserId,
        COUNT(*) AS TotalQuestions,
        SUM(rp.Score) AS TotalScore,
        AVG(rp.ViewCount) AS AvgViewCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5 -- Only top 5 posts for each user
    GROUP BY 
        rp.OwnerUserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    tps.TotalQuestions,
    tps.TotalScore,
    tps.AvgViewCount,
    ARRAY_AGG(DISTINCT pt.Name) AS PostTypes
FROM 
    Users u
JOIN 
    TopPostStats tps ON u.Id = tps.OwnerUserId
JOIN 
    Posts p ON p.OwnerUserId = u.Id
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    u.Id, tps.TotalQuestions, tps.TotalScore, tps.AvgViewCount
ORDER BY 
    tps.TotalScore DESC, u.Reputation DESC
LIMIT 10;
