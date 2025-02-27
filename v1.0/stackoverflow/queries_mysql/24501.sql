
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  
    WHERE 
        u.Reputation > 1000  
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        TotalPosts, 
        TotalQuestions, 
        TotalAnswers, 
        TotalBounties,
        RANK() OVER (ORDER BY TotalPosts DESC, Reputation DESC) AS PostRank
    FROM 
        UserStats
),
QuestionStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS QuestionCount,
        AVG(p.Score) AS AvgScore,
        MAX(p.ViewCount) AS MaxViews,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS TagsUsed
    FROM 
        Posts p
    JOIN 
        (SELECT TRIM(BOTH '<>' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS Tag
         FROM 
         (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL 
          SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1) AS Tag ON true
    JOIN 
        Tags t ON t.TagName = Tag
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.TotalPosts,
    QS.QuestionCount,
    QS.AvgScore,
    QS.MaxViews,
    QS.TagsUsed,
    COALESCE(u.TotalBounties, 0) AS TotalBounties
FROM 
    TopUsers u
LEFT JOIN 
    QuestionStats QS ON u.UserId = QS.OwnerUserId
WHERE 
    u.PostRank <= 10 
ORDER BY 
    u.PostRank;
