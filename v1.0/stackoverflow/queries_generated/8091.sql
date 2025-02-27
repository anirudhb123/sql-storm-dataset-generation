WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId 
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY SUM(p.Score) DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.Reputation,
    COUNT(rp.PostId) AS TotalPosts,
    SUM(rp.Score) AS TotalScore,
    SUM(rp.ViewCount) AS TotalViews,
    SUM(rp.CommentCount) AS TotalComments,
    SUM(rp.AnswerCount) AS TotalAnswers
FROM 
    TopUsers tu
JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId
WHERE 
    tu.UserRank <= 10
GROUP BY 
    tu.UserId, tu.DisplayName, tu.Reputation
ORDER BY 
    TotalScore DESC, TotalPosts DESC;
