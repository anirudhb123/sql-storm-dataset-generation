
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(p.Tags, '><') AS tag_array
    JOIN 
        Tags t ON t.TagName = TRIM(BOTH '<>' FROM tag_array.value)
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.CreationDate, p.ViewCount, p.Score, p.AnswerCount
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        SUM(b.Class) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.Reputation,
    up.TotalPosts,
    up.TotalScore,
    up.TotalBadges,
    rp.Title,
    rp.Tags,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.AnswerCount,
    pH.CloseCount,
    pH.DeleteCount,
    pH.ReopenCount
FROM 
    UserStats up
JOIN 
    RankedPosts rp ON up.UserId = rp.UserPostRank
LEFT JOIN 
    PostHistoryStats pH ON rp.PostId = pH.PostId
WHERE 
    up.Reputation > 1000
ORDER BY 
    up.TotalScore DESC, rp.Score DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
