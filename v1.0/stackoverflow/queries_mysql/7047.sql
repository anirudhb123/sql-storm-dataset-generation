
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        @row_number := IF(@prev_user = p.OwnerUserId, @row_number + 1, 1) AS VoteRank,
        @prev_user := p.OwnerUserId,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId,
        (SELECT @row_number := 0, @prev_user := NULL) AS init
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.CreationDate
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN COALESCE(b.Class, 0) = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN COALESCE(b.Class, 0) = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN COALESCE(b.Class, 0) = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    us.DisplayName,
    us.TotalPosts,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    COUNT(rp.PostId) AS ActivePostCount,
    AVG(rp.UpVotes - rp.DownVotes) AS AverageVoteDifference
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId
WHERE 
    rp.VoteRank <= 5
GROUP BY 
    us.DisplayName, us.TotalPosts, us.GoldBadges, us.SilverBadges, us.BronzeBadges
ORDER BY 
    AverageVoteDifference DESC, us.TotalPosts ASC;
