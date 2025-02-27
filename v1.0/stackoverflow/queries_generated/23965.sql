WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2020-01-01'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.PostTypeId
),
RecentActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        COUNT(DISTINCT c.Id) AS CommentsMade,
        COUNT(DISTINCT b.Id) AS BadgesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.CreationDate >= NOW() - INTERVAL '30 days'
    LEFT JOIN 
        Comments c ON u.Id = c.UserId AND c.CreationDate >= NOW() - INTERVAL '30 days'
    LEFT JOIN 
        Badges b ON u.Id = b.UserId AND b.Date >= NOW() - INTERVAL '30 days'
    WHERE 
        u.Reputation IS NOT NULL
    GROUP BY 
        u.Id, u.DisplayName
),
PostCallouts AS (
    SELECT
        DISTINCT p.Id AS PostId,
        CASE
            WHEN ph.PostHistoryTypeId = 10 THEN 'Closed: ' || cr.Name
            WHEN ph.PostHistoryTypeId = 11 THEN 'Reopened'
            WHEN ph.PostHistoryTypeId = 12 THEN 'Deleted'
            ELSE 'Other'
        END AS Status
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.CreationDate >= '2023-01-01'
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Rank,
    ra.UserId,
    ra.DisplayName,
    ra.PostsCreated,
    ra.CommentsMade,
    ra.BadgesReceived,
    pc.Status
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentActivity ra ON ra.PostsCreated > 0 OR ra.CommentsMade > 0
LEFT JOIN 
    PostCallouts pc ON pc.PostId = rp.PostId
WHERE 
    (rp.UpVotes - rp.DownVotes) > 0
    AND rp.Rank <= 5
    AND (ra.PostsCreated IS NULL OR ra.PostsCreated > 1)
ORDER BY 
    rp.Rank, ra.DisplayName NULLS LAST;
