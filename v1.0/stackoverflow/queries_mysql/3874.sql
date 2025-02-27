
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', '), 'No Tags') AS TagList
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS tag
         FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers
         WHERE CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 1 YEAR)
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
        p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 1 YEAR)
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
