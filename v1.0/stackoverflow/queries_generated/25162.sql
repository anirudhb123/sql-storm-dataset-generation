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
        UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS tag ON true
    LEFT JOIN
        Tags t ON tag = t.TagName
    WHERE
        p.PostTypeId = 1  -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY
        p.Id, u.DisplayName
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
        b.Date >= NOW() - INTERVAL '1 year'
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
    f.TagAggregated,
    COALESCE(f.BadgeName, 'No Badge') AS UserBadge,
    COALESCE(f.BadgeClass, 0) AS BadgeClass,
    f.ScoreRank
FROM 
    FinalRanking f
WHERE 
    f.ScoreRank <= 10  -- Top 10 in the ranking
ORDER BY 
    f.ScoreRank;
