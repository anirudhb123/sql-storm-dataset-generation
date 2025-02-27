WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
RecentUserActivities AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        RANK() OVER (ORDER BY COUNT(DISTINCT c.Id) + COUNT(DISTINCT v.Id) DESC) AS ActivityRank
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.CreationDate >= NOW() - INTERVAL '5 years'
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS ClosedDate,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY 
        ph.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldCount,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverCount,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score AS PostScore,
    p.ViewCount,
    u.DisplayName AS UserName,
    ua.CommentCount AS UserComments,
    rb.GoldCount,
    rb.SilverCount,
    rb.BronzeCount,
    COALESCE(cp.ClosedDate, 'Not Closed') AS PostClosedDate,
    COALESCE(cp.CloseReasons, 'N/A') AS PostCloseReasons,
    ARRAY_AGG(DISTINCT u1.DisplayName) AS RelatedUsers
FROM 
    RankedPosts p
JOIN 
    RecentUserActivities ua ON ua.ActivityRank <= 10
LEFT JOIN 
    UserBadges rb ON ua.UserId = rb.UserId
LEFT JOIN 
    ClosedPosts cp ON p.PostId = cp.PostId
LEFT JOIN 
    Posts related ON related.ParentId = p.PostId
LEFT JOIN 
    Users u ON u.Id = related.OwnerUserId
WHERE 
    p.PostRank <= 5
GROUP BY 
    p.PostId, u.DisplayName, ua.CommentCount, rb.GoldCount, rb.SilverCount, rb.BronzeCount, cp.ClosedDate, cp.CloseReasons
ORDER BY 
    p.Score DESC, ua.CommentCount DESC
LIMIT 20;
