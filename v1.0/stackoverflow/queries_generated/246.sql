WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.OwnerUserId,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS UserViewRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.OwnerDisplayName,
    CASE 
        WHEN rp.Rank <= 5 THEN 'Top Rank'
        ELSE 'Other Rank'
    END AS PostRankCategory,
    pp.PostedDate AS RecentlyEditedDate
FROM 
    RankedPosts rp
LEFT JOIN 
    Posts pp ON rp.PostId = pp.Id AND pp.LastEditDate >= DATEADD(month, -3, GETDATE())
WHERE 
    rp.UserViewRank <= 10 OR rp.AnswerCount > 5
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;

SELECT 
    DISTINCT 
    COALESCE(t.TagName, 'No Tags') AS TagName
FROM 
    Tags t
LEFT JOIN 
    Posts p ON p.Tags LIKE '%' + t.TagName + '%'
WHERE 
    p.OwnerUserId IS NOT NULL AND 
    p.CreationDate < GETDATE() AND 
    p.Score > 0

UNION

SELECT 
    'All Time Hot' AS TagName
WHERE 
    EXISTS (
        SELECT 1 
        FROM Posts p 
        WHERE p.ViewCount >= 10000
    );
