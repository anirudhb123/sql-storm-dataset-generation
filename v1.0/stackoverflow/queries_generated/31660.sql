WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
VoteCounts AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostActivity AS (
    SELECT 
        ph.PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        MAX(v.CreationDate) AS LastVoteDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        ph.PostId, p.Title, p.CreationDate
),
RankedPosts AS (
    SELECT 
        pa.*,
        ROW_NUMBER() OVER (PARTITION BY pa.OwnerUserId ORDER BY pa.CommentCount DESC, pa.VoteCount DESC) AS PostRank
    FROM 
        PostActivity pa
)
SELECT 
    r.Level,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    u.DisplayName AS Author,
    COALESCE(uc.UpVotes, 0) AS UpVotes,
    COALESCE(uc.DownVotes, 0) AS DownVotes,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges
FROM 
    RecursivePostHierarchy r
JOIN 
    RankedPosts rp ON r.PostId = rp.PostId
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    VoteCounts uc ON rp.PostId = uc.PostId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    r.Level <= 3
ORDER BY 
    r.Level, UpVotes DESC, DownVotes ASC;
