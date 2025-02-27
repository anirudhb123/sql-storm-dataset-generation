
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(day, -30, '2024-10-01 12:34:56')
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        RecentPosts rp ON p.ParentId = rp.PostId
    WHERE 
        p.CreationDate >= DATEADD(day, -30, '2024-10-01 12:34:56')
),
UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        value AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(Tags, '><')
    WHERE 
        PostTypeId = 1
    GROUP BY 
        value
    ORDER BY 
        TagCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstChangeDate,
        MAX(ph.CreationDate) AS LastChangeDate,
        COUNT(DISTINCT ph.UserId) AS EditorCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    u.DisplayName AS OwnerName,
    upc.PostCount,
    phs.FirstChangeDate,
    phs.LastChangeDate,
    phs.EditorCount,
    (SELECT 
        STRING_AGG(t.Tag, ', ') WITHIN GROUP (ORDER BY t.TagCount DESC)
     FROM 
        TopTags t) AS TopTags
FROM 
    RecentPosts rp
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserPostCounts upc ON u.Id = upc.UserId
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
WHERE 
    rp.Score > (SELECT AVG(Score) * 0.75 FROM Posts)
ORDER BY 
    rp.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
