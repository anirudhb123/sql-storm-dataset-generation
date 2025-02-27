
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        @row_number := IF(@owner_user_id = p.OwnerUserId, @row_number + 1, 1) AS Rank,
        @owner_user_id := p.OwnerUserId
    FROM 
        Posts p, (SELECT @row_number := 0, @owner_user_id := NULL) AS init
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    ORDER BY 
        p.OwnerUserId, p.Score DESC
),
UserBadges AS (
    SELECT 
        b.UserId,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
TopPostTitles AS (
    SELECT 
        rp.PostId,
        rp.Title,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    WHERE 
        rp.Rank <= 5
)
SELECT 
    tpt.PostId,
    tpt.Title,
    COALESCE(tpt.GoldBadges, 0) AS GoldBadges,
    COALESCE(tpt.SilverBadges, 0) AS SilverBadges,
    COALESCE(tpt.BronzeBadges, 0) AS BronzeBadges,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM 
    TopPostTitles tpt
LEFT JOIN 
    Comments c ON tpt.PostId = c.PostId
LEFT JOIN 
    Votes v ON tpt.PostId = v.PostId
GROUP BY 
    tpt.PostId, tpt.Title, tpt.GoldBadges, tpt.SilverBadges, tpt.BronzeBadges
HAVING 
    (COALESCE(tpt.GoldBadges, 0) + COALESCE(tpt.SilverBadges, 0) + COALESCE(tpt.BronzeBadges, 0)) > 3
ORDER BY 
    UpVotes DESC, tpt.Title ASC;
