WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        LATERAL STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><') AS tag_arr ON TRUE
    LEFT JOIN 
        Tags t ON tag_arr.value::int = t.Id
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
TopRankedPosts AS (
    SELECT 
        RP.*, 
        RANK() OVER (ORDER BY RP.Score DESC, RP.ViewCount DESC) AS Rank
    FROM 
        RankedPosts RP
)
SELECT 
    TRP.*,
    COALESCE(badge_counts.GoldBadges, 0) AS GoldBadges,
    COALESCE(badge_counts.SilverBadges, 0) AS SilverBadges,
    COALESCE(badge_counts.BronzeBadges, 0) AS BronzeBadges
FROM 
    TopRankedPosts TRP
LEFT JOIN (
    SELECT 
        UserId, 
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
) badge_counts ON TRP.OwnerName = badge_counts.UserId
WHERE 
    TRP.Rank <= 10  -- Top 10 questions
ORDER BY 
    TRP.Rank;
