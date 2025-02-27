
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') AS TagsAggregated
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        (
            SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.tags, '><', numbers.n), '><', -1) AS tag
            FROM
            (
                SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
                UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
            ) numbers INNER JOIN Posts p ON CHAR_LENGTH(p.tags) - CHAR_LENGTH(REPLACE(p.tags, '><', '')) >= numbers.n - 1
        ) AS tag ON true
    LEFT JOIN
        Tags t ON tag = t.TagName
    WHERE
        p.PostTypeId = 1  
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
RankedWithBadges AS (
    SELECT
        rp.*,
        b.Name AS BadgeName,
        b.Class AS BadgeClass
    FROM
        RankedPosts rp
    LEFT JOIN 
        Badges b ON rp.PostId = b.UserId
    WHERE
        b.Date >= NOW() - INTERVAL 1 YEAR
),
FinalRanking AS (
    SELECT
        r.*,
        @rank := IF(@prev_score = r.Score, @rank, @rank + 1) AS ScoreRank,
        @prev_score := r.Score
    FROM
        RankedWithBadges r,
        (SELECT @rank := 0, @prev_score := NULL) rnk
    ORDER BY r.Score DESC, r.ViewCount DESC
)
SELECT
    f.PostId,
    f.Title,
    f.OwnerDisplayName,
    f.ViewCount,
    f.CommentCount,
    f.TagsAggregated,
    COALESCE(f.BadgeName, 'No Badge') AS UserBadge,
    COALESCE(f.BadgeClass, 0) AS BadgeClass,
    f.ScoreRank
FROM 
    FinalRanking f
WHERE 
    f.ScoreRank <= 10  
ORDER BY 
    f.ScoreRank;
