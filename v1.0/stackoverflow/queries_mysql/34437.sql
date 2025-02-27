
WITH RECURSIVE RecentPosts AS (
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
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 30 DAY
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
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 30 DAY
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
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    INNER JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 10
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
        GROUP_CONCAT(t.Tag ORDER BY t.TagCount DESC SEPARATOR ', ')
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
LIMIT 50;
