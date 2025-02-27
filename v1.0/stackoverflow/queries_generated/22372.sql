WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) as RN
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostVoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(ph.Comment, 'Not provided') AS CloseReason,
        p.ClosedDate
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    WHERE 
        p.ClosedDate IS NOT NULL
),
FinalSummary AS (
    SELECT 
        up.Id AS UserId,
        COUNT(DISTINCT rp.PostId) AS HighScoringPosts,
        COALESCE(SUM(ub.GoldBadges) + SUM(ub.SilverBadges) + SUM(ub.BronzeBadges), 0) AS TotalBadges,
        COUNT(DISTINCT cp.PostId) AS ClosedPostsCount
    FROM 
        Users up
    LEFT JOIN 
        RankedPosts rp ON up.Id = rp.OwnerUserId
    LEFT JOIN 
        UserBadges ub ON up.Id = ub.UserId
    LEFT JOIN 
        ClosedPosts cp ON up.Id = (SELECT OwnerUserId FROM Posts WHERE Id = cp.PostId)
    GROUP BY 
        up.Id
)
SELECT 
    fs.UserId,
    fs.HighScoringPosts,
    fs.TotalBadges,
    fs.ClosedPostsCount,
    (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = fs.UserId AND CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 month') AS RecentPostsCount,
    (SELECT COUNT(*) FROM Comments WHERE UserId = fs.UserId) AS CommentsMade
FROM 
    FinalSummary fs
ORDER BY 
    fs.HighScoringPosts DESC,
    fs.TotalBadges DESC;
