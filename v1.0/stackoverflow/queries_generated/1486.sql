WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
TopUsers AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS TotalQuestions,
        SUM(Score) AS TotalScore
    FROM 
        RankedPosts
    GROUP BY 
        OwnerUserId
    HAVING 
        COUNT(*) > 5 -- Only consider users with more than 5 questions
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS Badges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    ru.OwnerDisplayName,
    ru.TotalQuestions,
    ru.TotalScore,
    COALESCE(ub.Badges, 'No Badges') AS Badges,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
    AVG(rp.ViewCount) AS AverageViews
FROM 
    TopUsers ru
LEFT JOIN 
    UserBadges ub ON ru.OwnerUserId = ub.UserId
LEFT JOIN 
    Posts p ON p.OwnerUserId = ru.OwnerUserId
LEFT JOIN 
    Comments c ON c.PostId = p.Id
LEFT JOIN 
    Votes v ON v.PostId = p.Id
LEFT JOIN 
    RankedPosts rp ON rp.OwnerUserId = ru.OwnerUserId
WHERE 
    rp.Rank = 1 
GROUP BY 
    ru.OwnerDisplayName, ru.TotalQuestions, ru.TotalScore, ub.Badges
ORDER BY 
    ru.TotalScore DESC
FETCH FIRST 10 ROWS ONLY;
