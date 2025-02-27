WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Focus on questions only
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount, -- Sum upvotes
        SUM(v.VoteTypeId = 3) AS DownVoteCount -- Sum downvotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerDisplayName, rp.CreationDate, rp.Score, rp.ViewCount
    HAVING 
        COUNT(c.Id) > 5  -- Only consider posts with more than 5 comments
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
)
SELECT 
    fp.Title,
    fp.OwnerDisplayName,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.CommentCount,
    fp.UpVoteCount,
    fp.DownVoteCount,
    ub.BadgeCount
FROM 
    FilteredPosts fp
JOIN 
    UserBadges ub ON fp.OwnerUserId = ub.UserId
ORDER BY 
    fp.Score DESC, 
    fp.ViewCount DESC
LIMIT 10;
