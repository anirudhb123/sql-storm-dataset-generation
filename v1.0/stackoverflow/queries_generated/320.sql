WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS PostRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, DisplayName, PostCount, TotalScore 
    FROM 
        UserPostStats
    WHERE 
        PostRank <= 10
),
CommentStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        AVG(LENGTH(c.Text)) AS AverageCommentLength
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.TotalScore,
    COALESCE(cs.CommentCount, 0) AS TotalComments,
    COALESCE(cs.AverageCommentLength, 0) AS AvgCommentLength,
    CASE 
        WHEN tu.TotalScore > 1000 THEN 'High'
        WHEN tu.TotalScore BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS ScoreCategory
FROM 
    TopUsers tu
LEFT JOIN 
    CommentStatistics cs ON tu.UserId = cs.OwnerUserId
ORDER BY 
    tu.PostCount DESC, tu.TotalScore DESC;

WITH PostHistoryCount AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS HistoryCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
),
PopularPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.ViewCount,
        phc.HistoryCount,
        DENSE_RANK() OVER (ORDER BY p.ViewCount DESC) AS PopularityRank
    FROM 
        Posts p
    JOIN 
        PostHistoryCount phc ON p.Id = phc.PostId
    WHERE 
        p.ViewCount > 1000
)
SELECT 
    pp.Title,
    pp.ViewCount,
    pp.HistoryCount,
    pp.PopularityRank,
    CASE 
        WHEN pp.HistoryCount > 10 THEN 'Frequently Edited'
        ELSE 'Rarely Edited'
    END AS EditFrequency,
    pht.Name AS PostHistoryType
FROM 
    PopularPosts pp
LEFT JOIN 
    PostHistoryTypes pht ON pp.Id = pht.Id
WHERE 
    pp.PopularityRank <= 5;
