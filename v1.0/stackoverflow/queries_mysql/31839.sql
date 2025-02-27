
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        @row_number := IF(@prev_owner_user_id = p.OwnerUserId, @row_number + 1, 1) AS PostRank,
        @prev_owner_user_id := p.OwnerUserId
    FROM 
        Posts p,
        (SELECT @row_number := 0, @prev_owner_user_id := NULL) AS vars
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0 
    ORDER BY 
        p.OwnerUserId, p.CreationDate DESC
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        SUM(p.Score) AS TotalScore,
        AVG(p.Score) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 
    GROUP BY 
        u.Id, u.DisplayName
),
LatestPostStats AS (
    SELECT 
        p.OwnerUserId,
        MAX(p.ViewCount) AS MaxViewCount,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.OwnerUserId
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalQuestions,
        us.TotalScore,
        us.AverageScore,
        lps.MaxViewCount,
        lps.CommentCount,
        @user_rank := @user_rank + 1 AS UserRank
    FROM 
        UserStatistics us,
        (SELECT @user_rank := 0) AS init
    JOIN 
        LatestPostStats lps ON us.UserId = lps.OwnerUserId
    ORDER BY 
        us.TotalScore DESC
)
SELECT 
    cu.DisplayName AS TopUser,
    cu.TotalQuestions,
    cu.TotalScore,
    cu.AverageScore,
    cu.MaxViewCount,
    cu.CommentCount,
    COUNT(DISTINCT ph.Id) AS TotalPostHistoryActions,
    GROUP_CONCAT(DISTINCT pht.Name ORDER BY pht.Name SEPARATOR ', ') AS RecentPostHistoryTypeNames
FROM 
    TopUsers cu
LEFT JOIN 
    Posts p ON cu.UserId = p.OwnerUserId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE 
    cu.UserRank <= 10 
GROUP BY 
    cu.UserId, cu.DisplayName, cu.TotalQuestions, cu.TotalScore, cu.AverageScore, cu.MaxViewCount, cu.CommentCount
ORDER BY 
    cu.TotalScore DESC;
