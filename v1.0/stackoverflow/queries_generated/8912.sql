WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        pt.Name AS PostType,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.AnswerCount,
    rp.CommentCount,
    rp.PostType,
    rp.OwnerDisplayName,
    rp.OwnerReputation
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.PostType, rp.Score DESC;

WITH MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        u.Id
    HAVING 
        COUNT(p.Id) > 10
)

SELECT 
    mau.UserId,
    mau.DisplayName,
    mau.PostCount,
    mau.PositivePosts,
    mau.NegativePosts,
    mau.TotalViews,
    ROW_NUMBER() OVER (ORDER BY mau.PostCount DESC) AS UserRank
FROM 
    MostActiveUsers mau
ORDER BY 
    mau.TotalViews DESC
LIMIT 10;
