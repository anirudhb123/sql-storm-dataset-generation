WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        LATERAL string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') AS t ON true
    GROUP BY 
        p.Id
),
PostWithBadgeCounts AS (
    SELECT 
        up.Id AS PostId,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        RankedPosts up
    LEFT JOIN 
        Users u ON up.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        up.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.*,
        p.Title,
        p.OwnerUserId,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN JSON_BUILD_OBJECT('Type', ph.PostHistoryTypeId, 'Reason', c.Name)
            ELSE JSON_BUILD_OBJECT('Type', ph.PostHistoryTypeId, 'Details', ph.Comment)
        END AS HistoryDetails
    FROM 
        PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    LEFT JOIN CloseReasonTypes c ON ph.Comment::int = c.Id
),
FinalResult AS (
    SELECT 
        r.Title,
        r.OwnerUserId,
        r.CreationDate,
        r.ViewCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        COUNT(pv.Id) AS VoteCount,
        CASE 
            WHEN r.Score >= 0 THEN 'Positive'
            WHEN r.Score < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS ScoreCategory,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        RankedPosts r
    LEFT JOIN 
        PostWithBadgeCounts b ON r.Id = b.PostId
    LEFT JOIN 
        Votes pv ON r.Id = pv.PostId
    LEFT JOIN 
        LATERAL string_to_array(substring(r.Tags, 2, length(r.Tags)-2), '><') AS t ON true
    GROUP BY 
        r.Title, r.OwnerUserId, r.CreationDate, r.ViewCount, b.BadgeCount
)
SELECT 
    f.Title,
    f.OwnerUserId,
    f.CreationDate,
    f.ViewCount,
    f.BadgeCount,
    f.VoteCount,
    f.ScoreCategory,
    CASE 
        WHEN f.Tags IS NULL THEN 'No Tags'
        ELSE f.Tags
    END AS FormattedTags
FROM 
    FinalResult f
WHERE 
    f.ViewCount > 100
ORDER BY 
    f.ScoreCategory DESC, f.ViewCount DESC;
