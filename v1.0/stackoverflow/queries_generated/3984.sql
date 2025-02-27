WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Score IS NOT NULL
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(case when v.VoteTypeId = 2 then 1 else 0 end), 0) AS TotalUpvotes,
        COALESCE(SUM(case when v.VoteTypeId = 3 then 1 else 0 end), 0) AS TotalDownvotes,
        COUNT(u.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
CloseReasons AS (
    SELECT 
        ph.UserId,
        Count(DISTINCT ph.PostId) AS TotalPostsClosed,
        MAX(crt.Name) AS LastCloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON ph.Comment::jsonb->>'reason'::int = crt.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.UserId
)
SELECT 
    u.DisplayName,
    ua.TotalPosts,
    ua.TotalUpvotes,
    ua.TotalDownvotes,
    COUNT(DISTINCT rp.Id) AS TotalRankedPosts,
    COALESCE(cr.TotalPostsClosed, 0) AS TotalPostsClosed,
    cr.LastCloseReason
FROM 
    Users u
LEFT JOIN 
    UserActivity ua ON u.Id = ua.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.PostRank <= 5
LEFT JOIN 
    CloseReasons cr ON u.Id = cr.UserId
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.DisplayName, ua.TotalPosts, ua.TotalUpvotes, ua.TotalDownvotes, cr.TotalPostsClosed, cr.LastCloseReason
ORDER BY 
    ua.TotalUpvotes DESC, TotalRankedPosts DESC;
