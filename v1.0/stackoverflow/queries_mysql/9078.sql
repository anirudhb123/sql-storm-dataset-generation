
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        @row_number := IF(@current_user = p.OwnerUserId, @row_number + 1, 1) AS Rank,
        @current_user := p.OwnerUserId
    FROM 
        Posts p,
        (SELECT @row_number := 0, @current_user := NULL) AS vars
    WHERE 
        p.PostTypeId = 1 
    ORDER BY 
        p.OwnerUserId, p.Score DESC, p.CreationDate DESC
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    pa.CommentCount,
    pa.UpVoteCount,
    pa.DownVoteCount,
    ub.BadgeCount,
    rp.Rank
FROM 
    RankedPosts rp
JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
JOIN 
    PostActivity pa ON rp.PostId = pa.PostId
WHERE 
    rp.Rank <= 5 
ORDER BY 
    ub.BadgeCount DESC, rp.ViewCount DESC;
