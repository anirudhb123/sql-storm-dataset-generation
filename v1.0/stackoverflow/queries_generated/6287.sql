WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND -- Only questions
        p.CreationDate >= (NOW() - INTERVAL '1 year') -- From the last year
    GROUP BY 
        p.Id
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount, -- Answers posted
        SUM(CASE WHEN bh.UserId IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount -- Badges earned
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges bh ON u.Id = bh.UserId
    GROUP BY 
        u.Id
)
SELECT 
    up.DisplayName,
    up.Reputation,
    COUNT(rp.PostId) AS QuestionsAnswered,
    SUM(rp.Score) AS TotalScore,
    SUM(rp.ViewCount) AS TotalViews,
    us.BadgeCount
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
JOIN 
    UserStats us ON up.Id = us.UserId
WHERE 
    rp.Rank <= 5 -- Only top 5 questions per user
GROUP BY 
    up.Id
ORDER BY 
    TotalScore DESC, TotalViews DESC
LIMIT 10;
