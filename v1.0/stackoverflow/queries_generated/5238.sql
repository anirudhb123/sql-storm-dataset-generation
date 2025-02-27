WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS Upvotes,
        SUM(v.VoteTypeId = 3) AS Downvotes,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(a.Id) DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
), UserBadges AS (
    SELECT 
        ub.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    JOIN 
        Users ub ON b.UserId = ub.Id
    GROUP BY 
        ub.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.AnswerCount,
    rp.Upvotes,
    rp.Downvotes,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
WHERE 
    rp.OwnerPostRank <= 5
ORDER BY 
    rp.AnswerCount DESC, 
    rp.Upvotes DESC;
