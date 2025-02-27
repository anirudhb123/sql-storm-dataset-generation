WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND -- Only Questions
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts created in the last year
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        u.Id
    HAVING 
        COUNT(p.Id) >= 5 -- Users with at least 5 questions
)
SELECT 
    ru.DisplayName,
    ru.QuestionCount,
    ru.TotalScore,
    rp.Title,
    rp.Score,
    rp.CreationDate,
    ph.Comment AS LastEditComment,
    ph.CreationDate AS LastEditDate
FROM 
    TopUsers ru
JOIN 
    RankedPosts rp ON ru.UserId = rp.PostId
LEFT JOIN 
    PostHistory ph ON rp.PostId = ph.PostId 
    AND ph.PostHistoryTypeId = 4 -- Edit Title
WHERE 
    rp.UserPostRank <= 3 -- Top 3 posts per user
ORDER BY 
    ru.TotalScore DESC, 
    rp.Score DESC;
