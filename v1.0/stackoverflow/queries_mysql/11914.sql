
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS Answers,
        SUM(p.Score) AS TotalScore,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        Questions,
        Answers,
        TotalScore,
        TotalBounty,
        @row_num := @row_num + 1 AS Rank
    FROM 
        UserPostStats, (SELECT @row_num := 0) AS r
    ORDER BY 
        TotalScore DESC, PostCount DESC
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    Questions,
    Answers,
    TotalScore,
    TotalBounty
FROM 
    TopUsers
WHERE 
    Rank <= 10;
