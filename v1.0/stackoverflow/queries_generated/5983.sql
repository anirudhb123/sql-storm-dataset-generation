WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViewCount,
        SUM(p.AnswerCount) AS TotalAnswers
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(p.Id) > 10 -- Only users with more than 10 questions
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.TotalScore,
    tu.TotalViewCount,
    tu.TotalAnswers,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount
FROM 
    TopUsers tu
JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId
WHERE 
    rp.UserPostRank = 1 -- Latest post for each user
ORDER BY 
    tu.TotalScore DESC, tu.TotalViewCount DESC;
