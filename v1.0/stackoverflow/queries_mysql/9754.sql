
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1)) AS Tag
         FROM Posts p
         INNER JOIN (
             SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
             UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
             UNION ALL SELECT 9 UNION ALL SELECT 10
         ) n ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1) AS tag ON TRUE
    JOIN 
        Tags t ON t.TagName = tag.Tag
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
    ORDER BY 
        p.CreationDate DESC
),
PostScores AS (
    SELECT 
        rp.*,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        @rownum := @rownum + 1 AS ScoreRank
    FROM 
        RankedPosts rp
    CROSS JOIN (SELECT @rownum := 0) r
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    OwnerDisplayName,
    CommentCount,
    Tags,
    BadgeCount,
    ScoreRank
FROM 
    PostScores
WHERE 
    ScoreRank <= 10
ORDER BY 
    ScoreRank;
