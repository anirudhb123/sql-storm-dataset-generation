WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.VoteTypeId = 2) AS Upvotes,
        SUM(v.VoteTypeId = 3) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.Comment AS CloseReason,
        ph.CreationDate AS CloseDate,
        STRING_AGG(DISTINCT ph.UserDisplayName, ', ') AS ClosedBy
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId, ph.CreationDate
),
Tweets AS (
    SELECT 
        p.Id as PostId,
        COUNT(CASE WHEN p.Title LIKE '%tweeted%' THEN 1 END) AS TweetCount
    FROM 
        Posts p
    GROUP BY 
        p.Id
),
FinalMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        us.BadgeCount,
        us.Upvotes,
        us.Downvotes,
        COALESCE(cp.CloseReason, 'Not Closed') AS CloseReason,
        COALESCE(cp.CloseDate, 'N/A') AS CloseDate,
        COALESCE(cp.ClosedBy, 'N/A') AS ClosedBy,
        COALESCE(t.TweetCount, 0) AS TweetCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserStats us ON rp.PostId = us.UserId
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    LEFT JOIN 
        Tweets t ON rp.PostId = t.PostId
)
SELECT 
    PostId,
    Title,
    BadgeCount,
    Upvotes,
    Downvotes,
    CloseReason,
    CloseDate,
    ClosedBy,
    TweetCount
FROM 
    FinalMetrics
WHERE 
    BadgeCount > 0 
    AND Upvotes - Downvotes > 10
ORDER BY 
    TweetCount DESC,
    CloseDate DESC NULLS LAST;
