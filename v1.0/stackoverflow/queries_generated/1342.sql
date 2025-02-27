WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalScore,
        DENSE_RANK() OVER (ORDER BY us.TotalScore DESC) AS Rank
    FROM 
        UserPostStats us
    WHERE 
        us.PostCount > 0
)
SELECT 
    pu.DisplayName,
    COUNT(DISTINCT p.Id) AS PostsCreated,
    AVG(p.ViewCount) AS AvgViewCount,
    ARRAY_AGG(DISTINCT pt.Name) AS PostTypes,
    (SELECT COUNT(*) FROM Votes v WHERE v.UserId = pu.UserId) AS TotalVotes,
    COALESCE(MAX(b.Class), 0) AS HighestBadgeClass
FROM 
    TopUsers pu
LEFT JOIN 
    Posts p ON pu.UserId = p.OwnerUserId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Badges b ON pu.UserId = b.UserId
WHERE 
    pu.Rank <= 10
GROUP BY 
    pu.UserId, pu.DisplayName
ORDER BY 
    pu.TotalScore DESC
HAVING 
    COUNT(DISTINCT p.Id) > 5 OR COUNT(DISTINCT b.Id) > 0;
