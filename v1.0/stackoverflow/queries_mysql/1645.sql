
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        @row_number := IF(@prev_user = p.OwnerUserId, @row_number + 1, 1) AS RN,
        @prev_user := p.OwnerUserId
    FROM 
        Posts p,
        (SELECT @row_number := 0, @prev_user := NULL) AS vars
    WHERE 
        p.CreationDate >= '2023-10-01 12:34:56' 
        AND p.PostTypeId = 1
    ORDER BY 
        p.OwnerUserId, p.Score DESC
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(NULLIF(p.ViewCount, 0)) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.QuestionCount,
        us.TotalScore,
        us.AvgViewCount,
        RANK() OVER (ORDER BY us.TotalScore DESC) AS UserRank
    FROM 
        UserStats us
    WHERE 
        us.QuestionCount > 10
)
SELECT 
    pu.DisplayName AS UserDisplayName,
    rp.PostId,
    rp.Title AS PostTitle,
    rp.CreationDate AS PostDate,
    rp.Score AS PostScore,
    rp.ViewCount AS PostViewCount,
    tu.AvgViewCount AS UserAvgViewCount,
    tu.UserRank
FROM 
    RankedPosts rp
JOIN 
    TopUsers tu ON rp.PostId IN (
        SELECT 
            p.Id 
        FROM 
            Posts p 
        WHERE 
            p.OwnerUserId = tu.UserId
    )
JOIN 
    Users pu ON tu.UserId = pu.Id
WHERE 
    rp.RN = 1
ORDER BY 
    tu.UserRank, rp.Score DESC;
