WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())  -- Posts from the last year
), 
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN p.Score ELSE 0 END) AS PositiveScore,
        SUM(CASE WHEN p.CreationDate <= DATEADD(month, -6, GETDATE()) THEN 1 ELSE 0 END) AS OldPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
), 
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstEditDate,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (6, 4) THEN 1 END) AS TagEdits,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseVotes
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName,
    us.TotalPosts,
    us.PositiveScore,
    us.OldPosts,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    CASE 
        WHEN phd.FirstEditDate IS NOT NULL THEN 
            DATEDIFF(day, phd.FirstEditDate, GETDATE())
        ELSE 0 
    END AS DaysSinceFirstEdit,
    phd.TagEdits,
    phd.CloseVotes
FROM 
    UserStatistics us
JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId AND rp.rn <= 5 -- Get top 5 posts per user
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE 
    us.TotalPosts > 0
ORDER BY 
    us.PositiveScore DESC, rp.ViewCount DESC;
