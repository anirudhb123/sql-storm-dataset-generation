WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(COALESCE(p.Score, 0)) AS TotalPostScore,
        SUM(p.ViewCount) AS TotalViews,
        MAX(p.CreationDate) AS LastPost
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
ClosedPosts AS (
    SELECT 
        p.Id AS ClosedPostId, 
        p.Score AS ClosedPostScore,
        ph.CreationDate,
        STRING_AGG(DISTINCT c.Text, '; ') AS CloseReasons
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    LEFT JOIN 
        CloseReasonTypes crt ON ph.Comment::int = crt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, ph.CreationDate, p.Score
),
UserRanking AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.BadgeCount,
        us.TotalPostScore,
        us.TotalViews,
        us.LastPost,
        RANK() OVER (ORDER BY us.Reputation DESC, us.TotalPostScore DESC) AS UserRank
    FROM 
        UserStats us
)
SELECT 
    ur.DisplayName AS UserName,
    ur.Reputation,
    ur.BadgeCount,
    ur.TotalPostScore,
    ur.TotalViews,
    ur.LastPost,
    rp.Title,
    rp.PostId,
    rp.ViewCount,
    rp.CommentCount,
    cp.ClosePostId,
    cp.ClosedPostScore,
    cp.CloseReasons
FROM 
    UserRanking ur
LEFT JOIN 
    RankedPosts rp ON ur.UserId = rp.OwnerUserId AND rp.rn = 1
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.ClosedPostId
WHERE 
    (ur.Reputation > 1000 OR (ur.BadgeCount > 5 AND ur.TotalViews > 500)) 
    AND (cp.ClosedPostScore IS NOT NULL OR rp.ViewCount > 100)
ORDER BY 
    ur.UserRank, rp.ViewCount DESC
LIMIT 100;
