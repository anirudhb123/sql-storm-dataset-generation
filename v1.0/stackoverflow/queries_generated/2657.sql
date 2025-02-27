WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpvoteCount,
        SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownvoteCount,
        COALESCE(SUM(v.BountyAmount) OVER (PARTITION BY p.Id), 0) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        COALESCE(SUM(b.Class = 1)::int, 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2)::int, 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3)::int, 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.AnswerCount,
        ur.UserId,
        ur.Reputation,
        ur.BadgeCount,
        ur.GoldBadges,
        ur.SilverBadges,
        ur.BronzeBadges,
        rp.UpvoteCount,
        rp.DownvoteCount,
        rp.TotalBounty
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON u.Id = rp.OwnerUserId
    JOIN 
        UserReputation ur ON ur.UserId = rp.OwnerUserId
    WHERE 
        rp.UserRank <= 5
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    AnswerCount,
    Reputation,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    UpvoteCount,
    DownvoteCount,
    TotalBounty
FROM 
    FinalResults
WHERE 
    TotalBounty > 0
ORDER BY 
    Score DESC, CreationDate ASC
LIMIT 100;
