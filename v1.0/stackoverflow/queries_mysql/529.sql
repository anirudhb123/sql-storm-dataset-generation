
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        @row_number := IF(@prev_user = p.OwnerUserId, @row_number + 1, 1) AS PostRank,
        @prev_user := p.OwnerUserId
    FROM 
        Posts p, (SELECT @row_number := 0, @prev_user := NULL) r
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    ORDER BY 
        p.OwnerUserId, p.Score DESC
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
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
PostVoteCounts AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
MostVotedPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        ub.BadgeCount,
        pvc.UpVotes,
        pvc.DownVotes,
        @most_voted_rank := @most_voted_rank + 1 AS MostVotedRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    LEFT JOIN 
        PostVoteCounts pvc ON rp.Id = pvc.PostId, (SELECT @most_voted_rank := 0) r
    WHERE 
        rp.PostRank = 1
    ORDER BY 
        COALESCE(pvc.UpVotes - pvc.DownVotes, 0) DESC, rp.CreationDate DESC
)
SELECT 
    mvp.Title,
    mvp.CreationDate,
    mvp.BadgeCount,
    mvp.UpVotes,
    mvp.DownVotes,
    CASE 
        WHEN mvp.BadgeCount IS NULL THEN 'No Badges' 
        ELSE 'Has Badges' 
    END AS BadgeStatus
FROM 
    MostVotedPosts mvp
WHERE 
    mvp.MostVotedRank <= 10
ORDER BY 
    mvp.UpVotes DESC, mvp.CreationDate DESC;
