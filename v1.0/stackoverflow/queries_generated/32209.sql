WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RowNum
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId = 1 -- Only questions
),
PostVotes AS (
    SELECT 
        v.PostId,
        v.VoteTypeId,
        COUNT(*) AS VoteCount
    FROM 
        Votes v
    GROUP BY 
        v.PostId, v.VoteTypeId
),
UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldCount,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverCount,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    COALESCE(ps.VoteCount, 0) AS TotalVotes,
    COALESCE(ub.GoldCount, 0) AS GoldBadges,
    COALESCE(ub.SilverCount, 0) AS SilverBadges,
    COALESCE(ub.BronzeCount, 0) AS BronzeBadges
FROM 
    Users u
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.RowNum = 1 -- Get the top post
LEFT JOIN 
    PostVotes ps ON rp.PostId = ps.PostId AND ps.VoteTypeId = 2 -- Count of upvotes
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    u.Reputation > 1000 -- Only display users with reputation greater than 1000
ORDER BY 
    u.Reputation DESC;
