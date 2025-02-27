WITH RecursiveUserReputation AS (
    SELECT 
        u.Id,
        u.Reputation,
        u.CreationDate,
        0 AS Level
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000

    UNION ALL

    SELECT 
        u.Id,
        u.Reputation,
        u.CreationDate,
        Level + 1
    FROM 
        Users u
    INNER JOIN 
        RecursiveUserReputation r ON u.Reputation < r.Reputation AND r.Level < 5
), 
PostScoreSummary AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.Score) AS AverageScore,
        MAX(p.Score) AS MaxScore,
        MIN(p.Score) AS MinScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
), 
UserPostHistory AS (
    SELECT 
        uh.UserId,
        uh.PostCount,
        uh.TotalScore,
        u.DisplayName,
        u.Reputation
    FROM 
        PostScoreSummary uh
    JOIN 
        Users u ON uh.OwnerUserId = u.Id
)
SELECT 
    uph.DisplayName,
    uph.Reputation,
    uph.PostCount,
    uph.TotalScore,
    uph.AverageScore,
    uph.MaxScore,
    uph.MinScore,
    CASE 
        WHEN uph.TotalScore IS NULL THEN 'No posts'
        ELSE CONCAT('Total score: ', uph.TotalScore)
    END AS ScoreInfo,
    CASE 
        WHEN uph.Reputation IS NULL THEN 'Reputation unavailable'
        ELSE CONCAT('Reputation level: ', uph.Reputation)
    END AS ReputationInfo,
    COALESCE((
        SELECT 
            STRING_AGG(pt.Name, ', ') 
        FROM 
            Posts p
        JOIN 
            PostTypes pt ON p.PostTypeId = pt.Id 
        WHERE 
            p.OwnerUserId = uph.UserId
    ), '') AS PostTypeNames
FROM 
    UserPostHistory uph
LEFT JOIN 
    RecursiveUserReputation r ON uph.UserId = r.Id
WHERE 
    uph.Reputation > 1000
ORDER BY 
    uph.TotalScore DESC
LIMIT 10
OFFSET 0;
