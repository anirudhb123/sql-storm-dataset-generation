
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
        AND p.Score > 0
),
PopularTags AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
         SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
         SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 5
),
PostsWithComments AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    rp.Score,
    rp.OwnerName,
    COALESCE(pwc.CommentCount, 0) AS CommentCount,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    GROUP_CONCAT(DISTINCT pt.TagName) AS AssociatedTags
FROM 
    RankedPosts rp
LEFT JOIN 
    PostsWithComments pwc ON rp.PostId = pwc.PostId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    Posts p ON rp.PostId = p.Id
LEFT JOIN 
    PopularTags pt ON FIND_IN_SET(pt.TagName, REPLACE(p.Tags, '><', ',')) > 0
WHERE 
    rp.Rank <= 5
GROUP BY 
    rp.PostId, rp.Title, rp.ViewCount, rp.CreationDate, rp.Score, rp.OwnerName, pwc.CommentCount, cp.CloseCount
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
