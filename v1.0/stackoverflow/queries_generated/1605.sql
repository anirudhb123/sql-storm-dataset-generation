WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
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
        u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) -- Questions and Answers
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        pd.OwnerUserId,
        pd.PostId,
        pd.PostTypeId,
        pd.Score,
        pd.ViewCount,
        pd.CreationDate,
        pd.PostRank,
        COALESCE(UP.id, 'No Accepted Answer') AS AcceptedAnswerInfo
    FROM 
        PostDetails pd
    LEFT JOIN 
        Posts UP ON pd.AcceptedAnswerId = UP.Id
    WHERE 
        pd.PostRank <= 3 -- Top 3 posts per user in the last year
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.BadgeCount,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    tp.PostId,
    tp.PostTypeId,
    tp.Score,
    tp.ViewCount,
    tp.CreationDate,
    tp.AcceptedAnswerInfo
FROM 
    UserStats us
LEFT JOIN 
    TopPosts tp ON us.UserId = tp.OwnerUserId
WHERE 
    us.Reputation > (SELECT AVG(Reputation) FROM Users) -- Only users above average reputation
ORDER BY 
    us.Reputation DESC,
    tp.ViewCount DESC NULLS LAST;
