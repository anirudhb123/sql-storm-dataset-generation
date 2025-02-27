WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        PARENT.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Posts PARENT ON PARENT.Id = p.AcceptedAnswerId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '6 months'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate, PARENT.AcceptedAnswerId
),
ClosedPosts AS (
    SELECT 
        p.Id AS ClosedPostId,
        ph.UserId,
        ph.CreationDate AS CloseDate,
        CloseReasons.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON p.Id = ph.PostId
    JOIN 
        CloseReasonTypes CloseReasons ON CloseReasons.Id = ph.Comment
    WHERE 
        ph.PostHistoryTypeId = 10
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id
),
FinalStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerUserId,
        us.UserId,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        cp.ClosedPostId,
        cp.CloseDate,
        cp.CloseReason
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON us.UserId = rp.OwnerUserId
    LEFT JOIN 
        ClosedPosts cp ON cp.ClosedPostId = rp.PostId
)

SELECT 
    fs.PostId,
    fs.Title,
    fs.GoldBadges,
    fs.SilverBadges,
    fs.BronzeBadges,
    fs.CommentCount,
    fs.UpVoteCount,
    fs.DownVoteCount,
    CASE 
        WHEN fs.CloseReason IS NOT NULL THEN 'Closed: ' || fs.CloseReason
        ELSE 'Open' 
    END AS PostStatus,
    CASE 
        WHEN fs.GoldBadges > 0 THEN 'High Reputation User'
        WHEN fs.SilverBadges > 0 THEN 'Moderate Reputation User'
        ELSE 'New User'
    END AS UserType
FROM 
    FinalStats fs
WHERE 
    fs.CommentCount > 5 
    AND (fs.UpVoteCount - fs.DownVoteCount) > 0
ORDER BY 
    fs.UpVoteCount DESC, 
    fs.CommentCount DESC;
