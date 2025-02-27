WITH RecursivePostStats AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2) -- Questions and Answers
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount
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
),
TopPosts AS (
    SELECT 
        r.*, 
        ub.GoldBadges, 
        ub.SilverBadges, 
        ub.BronzeBadges
    FROM 
        RecursivePostStats r
    LEFT JOIN 
        UserBadges ub ON r.OwnerUserId = ub.UserId
    WHERE 
        r.UserPostRank <= 5
)
SELECT 
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    COALESCE(p.UpVotes, 0) AS UpVotes,
    COALESCE(p.DownVotes, 0) AS DownVotes,
    COALESCE(b.GoldBadges, 0) AS GoldBadges,
    COALESCE(b.SilverBadges, 0) AS SilverBadges,
    COALESCE(b.BronzeBadges, 0) AS BronzeBadges,
    CASE 
        WHEN p.ViewCount >= 1000 THEN 'High Views' 
        WHEN p.ViewCount BETWEEN 500 AND 999 THEN 'Moderate Views'
        ELSE 'Low Views'
    END AS ViewCategory
FROM 
    TopPosts p
LEFT JOIN 
    UserBadges b ON p.OwnerUserId = b.UserId
ORDER BY 
    p.Score DESC,
    p.ViewCount DESC;
