WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(rp.PostId) AS TotalPosts,
        SUM(rp.ViewCount) AS TotalViews,
        AVG(rp.Score) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalViews,
        AvgScore,
        RANK() OVER (ORDER BY TotalPosts DESC, AvgScore DESC) AS UserRank
    FROM 
        PostSummary
),
RecentPostIDs AS (
    SELECT 
        p.Id
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month'
),
CommentsSummary AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        AVG(c.Score) AS AvgCommentScore
    FROM 
        Comments c
    WHERE 
        c.PostId IN (SELECT Id FROM RecentPostIDs)
    GROUP BY 
        c.PostId
)

SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalViews,
    tu.AvgScore,
    COALESCE(ps.CommentCount, 0) AS PostCommentCount,
    COALESCE(ps.AvgCommentScore, 0) AS PostAvgCommentScore
FROM 
    TopUsers tu
LEFT JOIN 
    CommentsSummary ps ON tu.UserId = ps.PostId
WHERE 
    tu.UserRank <= 10
ORDER BY 
    tu.UserRank;
