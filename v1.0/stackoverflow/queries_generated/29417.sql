WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Score,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
AggregatedBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
AnsweredPosts AS (
    SELECT 
        p.Id AS QuestionId,
        COUNT(a.Id) AS AnswerCount,
        COALESCE(SUM(CASE WHEN a.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END), 0) AS UserAnswerCount,
        COALESCE(SUM(CASE WHEN a.OwnerUserId IS NULL THEN 1 ELSE 0 END), 0) AS CommunityAnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.Score,
    rp.Tags,
    rp.OwnerDisplayName,
    rp.OwnerReputation,
    ab.GoldBadges,
    ab.SilverBadges,
    ab.BronzeBadges,
    ap.UserAnswerCount,
    ap.CommunityAnswerCount
FROM 
    RankedPosts rp
LEFT JOIN 
    AggregatedBadges ab ON rp.OwnerDisplayName = ab.UserId
LEFT JOIN 
    AnsweredPosts ap ON rp.PostId = ap.QuestionId
WHERE 
    rp.Rank <= 5 -- Top 5 recent questions per tag
ORDER BY 
    rp.Tags, rp.CreationDate DESC;
