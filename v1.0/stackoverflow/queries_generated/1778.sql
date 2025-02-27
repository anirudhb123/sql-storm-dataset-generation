WITH RecentPostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
        AND p.PostTypeId = 1  -- Only Questions
        AND p.Deleted = 0  -- Assuming there's a Soft Delete indicator
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.Score
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY SUM(ps.ViewCount) DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        RecentPostStats ps ON u.Id = ps.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        CloseReasonTypes.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ON ph.Comment::int = CloseReasonTypes.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
)
SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(rps.ViewCount, 0) AS RecentPostViewCount,
    COUNT(cp.PostId) AS ClosedPostCount,
    SUM(rps.UpVotes - rps.DownVotes) AS NetVotes,
    STRING_AGG(DISTINCT cp.CloseReason, ', ') AS ClosedReasons
FROM 
    TopUsers u
LEFT JOIN 
    RecentPostStats rps ON u.UserId = rps.OwnerUserId
LEFT JOIN 
    ClosedPosts cp ON rps.PostId = cp.PostId
WHERE 
    u.UserRank <= 10  -- Get top 10 users by views
GROUP BY 
    u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC;
