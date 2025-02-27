WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND -- Only questions
        p.CreationDate > NOW() - INTERVAL '1 YEAR' -- Limit to last year
), TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        COUNT(p.Id) AS QuestionsCount
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
), PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS EditDate,
        ph.UserId,
        ph.Comment,
        p.Title
    FROM 
        PostHistory ph
    INNER JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5)
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    COUNT(DISTINCT rp.PostId) AS UniquePostsEdited,
    SUM(tu.TotalScore) AS TotalScore,
    SUM(tu.TotalViews) AS TotalViews,
    ARRAY_AGG(DISTINCT ph.EditDate ORDER BY ph.EditDate DESC) AS RecentEdits
FROM 
    TopUsers tu
LEFT JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId
LEFT JOIN 
    PostHistoryDetails ph ON rp.PostId = ph.PostId
GROUP BY 
    tu.UserId, tu.DisplayName
ORDER BY 
    TotalScore DESC, TotalViews DESC
LIMIT 10;
