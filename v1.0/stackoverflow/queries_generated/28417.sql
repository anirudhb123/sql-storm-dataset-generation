WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- only questions
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        CASE
            WHEN rp.ViewCount > 1000 THEN 'High'
            WHEN rp.ViewCount BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS Popularity,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,  -- UpMod
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes  -- DownMod
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.ViewCount, rp.AnswerCount, rp.CommentCount
),
BadgeStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.Popularity,
    ps.UpVotes,
    ps.DownVotes,
    bs.TotalBadges,
    bs.GoldBadges,
    bs.SilverBadges,
    bs.BronzeBadges
FROM 
    PostStats ps
JOIN 
    Users u ON ps.Author = u.DisplayName
JOIN 
    BadgeStats bs ON u.Id = bs.UserId
WHERE 
    ps.UpVotes > 5 OR ps.DownVotes > 2
ORDER BY 
    ps.ViewCount DESC, 
    ps.AnswerCount DESC;
