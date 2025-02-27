WITH PostDetails AS (
    SELECT 
        p.id AS PostId,
        p.title AS PostTitle,
        p.creationdate AS PostCreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.id) AS CommentCount,
        COUNT(DISTINCT v.id) AS VoteCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        MAX(BADGES.Date) FILTER (WHERE b.Class = 1) AS GoldBadgeDate,
        MAX(BADGES.Date) FILTER (WHERE b.Class = 2) AS SilverBadgeDate,
        MAX(BADGES.Date) FILTER (WHERE b.Class = 3) AS BronzeBadgeDate
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.id
    LEFT JOIN 
        Comments c ON p.id = c.PostId
    LEFT JOIN 
        Votes v ON p.id = v.PostId
    LEFT JOIN 
        Badges b ON u.id = b.UserId
    LEFT JOIN 
        (SELECT TagName FROM Tags) t ON t.id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.id, u.DisplayName
),
RankedPosts AS (
    SELECT 
        pd.*,
        ROW_NUMBER() OVER (ORDER BY pd.VoteCount DESC, pd.CommentCount DESC) AS Rank
    FROM 
        PostDetails pd
)
SELECT 
    rp.Rank,
    rp.PostId,
    rp.PostTitle,
    rp.OwnerDisplayName,
    rp.PostCreationDate,
    rp.CommentCount,
    rp.VoteCount,
    CASE 
        WHEN rp.GoldBadgeDate IS NOT NULL THEN 'Gold'
        WHEN rp.SilverBadgeDate IS NOT NULL THEN 'Silver'
        WHEN rp.BronzeBadgeDate IS NOT NULL THEN 'Bronze'
        ELSE 'No Badge'
    END AS BadgeStatus,
    ARRAY_TO_STRING(rp.Tags, ', ') AS TagsList
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 10 -- Top 10 posts
ORDER BY 
    rp.Rank;

-- This query selects the top 10 questions based on vote count and comment count,
-- including the author, creation date, badge status, and associated tags for benchmarking string processing.
