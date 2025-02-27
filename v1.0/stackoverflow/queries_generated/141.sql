WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName, p.CreationDate
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ph.UserDisplayName,
        ph.Comment,
        DENSE_RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) -- Closed, Reopened, Deleted
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    COALESCE(pb.HistoryRank, 0) AS PostHistoryRank,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    CASE 
        WHEN rp.PostRank = 1 THEN 'Latest Post'
        WHEN rp.PostRank <= 5 THEN 'Top 5 Recent Posts'
        ELSE NULL 
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryData pb ON rp.PostId = pb.PostId AND pb.HistoryRank = 1
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
WHERE 
    rp.CommentCount > 0
    AND (rp.UpVotes - rp.DownVotes) > 10
ORDER BY 
    rp.CreationDate DESC;
