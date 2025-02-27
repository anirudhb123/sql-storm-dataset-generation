
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(STRING_AGG(DISTINCT t.TagName, ', '), 'No Tags') AS TagList
    FROM 
        Posts p
    LEFT JOIN 
        STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') AS tag ON 1=1
    LEFT JOIN 
        Tags t ON t.TagName = tag.value
    WHERE 
        p.CreationDate >= CAST('2024-10-01' AS DATE) - DATEADD(YEAR, 1, 0)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= CAST('2024-10-01' AS DATE) - DATEADD(YEAR, 1, 0)
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(p.Id) > 5
),
LatestPostsWithComments AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.TagList,
        COUNT(c.Id) AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    WHERE 
        rp.rn = 1
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.TagList
)
SELECT 
    up.DisplayName,
    lp.Title,
    lp.CreationDate,
    lp.Score,
    lp.TagList,
    lp.CommentCount,
    CASE 
        WHEN lp.Score > 50 THEN 'High Engagement'
        WHEN lp.Score BETWEEN 20 AND 50 THEN 'Medium Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    PopularUsers up
JOIN 
    LatestPostsWithComments lp ON up.UserId = lp.PostId
ORDER BY 
    up.TotalScore DESC, lp.CommentCount DESC;
