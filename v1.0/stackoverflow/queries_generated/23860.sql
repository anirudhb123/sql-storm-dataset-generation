WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days' 
),

PostWithBadges AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS BadgeCount
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) b ON rp.OwnerUserId = b.UserId
    JOIN Users u ON u.Id = rp.OwnerUserId
),

CommentStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN c.Score > 0 THEN 1 ELSE 0 END) AS PositiveCommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '60 days'
    GROUP BY 
        p.Id
),

Final AS (
    SELECT 
        pwb.PostId,
        pwb.Title,
        pwb.CreationDate,
        pwb.OwnerDisplayName,
        pwb.BadgeCount,
        cs.CommentCount,
        cs.PositiveCommentCount,
        CASE 
            WHEN cs.CommentCount IS NULL THEN 'No Comments'
            WHEN cs.PositiveCommentCount::FLOAT / cs.CommentCount < 0.5 THEN 'Mostly Negative'
            ELSE 'Mixed or Positive'
        END AS CommentSentiment,
        COALESCE(LEFT(pw.Body, 200), 'No body content available.') AS ShortBody
    FROM 
        PostWithBadges pwb
    LEFT JOIN 
        CommentStats cs ON pwb.PostId = cs.PostId
    LEFT JOIN 
        Posts pw ON pw.Id = pwb.PostId
    WHERE 
        pwb.BadgeCount > 0 AND
        pw.CreationDate < NOW() - INTERVAL '30 days' 
    ORDER BY 
        pwb.BadgeCount DESC,
        pwb.CreationDate ASC
)

SELECT 
    *,
    CASE 
        WHEN OwnerDisplayName IS NULL THEN 'Anonymous'
        ELSE OwnerDisplayName 
    END AS DisplayName
FROM 
    Final
WHERE 
    CommentSentiment NOT IN ('No Comments')
ORDER BY 
    CommentCount DESC, CreationDate ASC;

This query provides a comprehensive view of the posts created in the last 30 days, enriching that information with badge counts and comment statistics, while applying various SQL constructs such as Common Table Expressions (CTEs), window functions, and CASE statements to handle various cases, including NULL checks and sentiment analysis based on comment scores.
