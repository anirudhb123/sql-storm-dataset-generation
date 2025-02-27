
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        COUNT(c.Id) AS CommentCount,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(DAY, -30, '2024-10-01 12:34:56')
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.AcceptedAnswerId, p.OwnerUserId
), 
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.AcceptedAnswerId,
        rp.OwnerUserId,
        rp.UserRank,
        rp.CommentCount,
        COALESCE(rp.UpVotes - rp.DownVotes, 0) AS NetVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserRank <= 3
), 
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    tp.CommentCount,
    tp.NetVotes,
    CASE 
        WHEN tp.AcceptedAnswerId IS NOT NULL THEN 'Accepted' 
        ELSE 'Not Accepted' 
    END AS AnswerStatus,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = tp.PostId AND v.VoteTypeId = 6) THEN 'Closed'
        ELSE 'Open' 
    END AS PostStatus
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.OwnerUserId = u.Id
JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    (ub.GoldBadges + ub.SilverBadges + ub.BronzeBadges) > 0
ORDER BY 
    tp.NetVotes DESC, 
    tp.CreationDate ASC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
