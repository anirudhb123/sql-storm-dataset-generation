
WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId, 
        PostCount
    FROM 
        UserPostCounts
    ORDER BY 
        PostCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        pt.Name AS PostTypeName,
        p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
)
SELECT 
    tu.UserId,
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.Score,
    pa.ViewCount,
    pa.OwnerDisplayName,
    pa.PostTypeName
FROM 
    TopUsers tu
LEFT JOIN 
    PostAnalytics pa ON tu.UserId = pa.OwnerUserId
ORDER BY 
    tu.PostCount DESC, 
    pa.Score DESC;
