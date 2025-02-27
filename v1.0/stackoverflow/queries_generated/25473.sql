WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' -- considering posts created in 2023
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, p.ViewCount
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= '2023-01-01'
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    tu.DisplayName,
    tu.TotalViews,
    tu.QuestionsCount,
    tu.AnswersCount,
    rp.Title,
    rp.ViewCount,
    rp.Tags
FROM 
    TopUsers tu
JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId
WHERE 
    rp.ViewRank <= 5 -- Top 5 viewed posts per user
ORDER BY 
    tu.TotalViews DESC, 
    rp.ViewCount DESC;
