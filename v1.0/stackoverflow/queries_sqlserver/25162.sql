
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagsAggregated
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '>') AS tag ON 1=1
    LEFT JOIN
        Tags t ON tag.value = t.TagName
    WHERE
        p.PostTypeId = 1  
        AND p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL '1 year'
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
        b.Date >= '2024-10-01 12:34:56' - INTERVAL '1 year'
),
FinalRanking AS (
    SELECT
        r.*,
        RANK() OVER (ORDER BY r.Score DESC, r.ViewCount DESC) AS ScoreRank
    FROM
        RankedWithBadges r
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
