WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.OwnerPostRank = 1
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldCount,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverCount,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.CreationDate,
    fp.OwnerDisplayName,
    fp.CommentCount,
    fp.UpVoteCount,
    fp.DownVoteCount,
    ub.GoldCount,
    ub.SilverCount,
    ub.BronzeCount,
    CASE 
        WHEN ub.GoldCount > 0 THEN 'Gold User'
        WHEN ub.SilverCount > 0 THEN 'Silver User'
        ELSE 'Regular User'
    END AS UserType
FROM 
    FilteredPosts fp
JOIN 
    UserBadges ub ON fp.OwnerDisplayName = ub.UserId
ORDER BY 
    fp.UpVoteCount DESC,
    fp.CommentCount DESC;
