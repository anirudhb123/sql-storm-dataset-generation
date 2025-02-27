
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        (SELECT DISTINCT UNNEST(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2)) AS TagName FROM Posts p) t ON TRUE
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
PostStatistics AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName,
        CommentCount,
        BadgeCount,
        Tags,
        @row_number:=IF(@prev_score = Score, @row_number + 1, 1) AS Rank,
        @prev_score := Score
    FROM 
        RankedPosts,
        (SELECT @row_number := 0, @prev_score := NULL) r
    ORDER BY 
        Score DESC, ViewCount DESC
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Body,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.OwnerDisplayName,
    ps.CommentCount,
    ps.BadgeCount,
    ps.Rank,
    CASE 
        WHEN ps.BadgeCount > 5 THEN 'Experienced User'
        WHEN ps.BadgeCount BETWEEN 1 AND 5 THEN 'Novice User'
        ELSE 'No Badges'
    END AS UserExperienceLevel,
    CONCAT('Tags: ', ps.Tags) AS TagList
FROM 
    PostStatistics ps
WHERE 
    ps.Rank <= 10 
ORDER BY 
    ps.Rank;
