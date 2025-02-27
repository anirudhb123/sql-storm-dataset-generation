WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Filter for questions
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostVoteAggregates AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    p.Title AS QuestionTitle,
    p.CreationDate,
    p.Score AS QuestionScore,
    p.ViewCount,
    COALESCE(up.Upvotes, 0) AS Upvotes,
    COALESCE(dn.Downvotes, 0) AS Downvotes,
    u.Reputation AS UserReputation,
    u.BadgeCount,
    CONCAT('Gold: ', u.GoldBadges, ', Silver: ', u.SilverBadges, ', Bronze: ', u.BronzeBadges) AS BadgeSummary,
    CASE 
        WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Answered' 
        ELSE 'Unanswered' 
    END AS AnswerStatus
FROM 
    RankedPosts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostVoteAggregates up ON p.PostId = up.PostId
LEFT JOIN 
    PostVoteAggregates dn ON p.PostId = dn.PostId
WHERE 
    p.Rank <= 5 -- Limit to top 5 questions per user by score
ORDER BY 
    u.Reputation DESC, p.Score DESC;
