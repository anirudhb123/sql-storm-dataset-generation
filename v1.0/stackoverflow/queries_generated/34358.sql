WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.CreationDate,
        p.Tags,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.Score > 0
        AND p.CreationDate > NOW() - INTERVAL '1 year'  -- Considering posts from the last year
),
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpvotesReceived,  -- Upvotes
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownvotesReceived,  -- Downvotes
        COUNT(DISTINCT p.Id) AS PostsCreated,
        COUNT(DISTINCT ph.PostId) AS PostHistoryEntries
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        u.Id
),
MostActiveUsers AS (
    SELECT 
        um.UserId,
        um.DisplayName,
        um.Reputation,
        um.UpvotesReceived,
        um.DownvotesReceived,
        um.PostsCreated,
        um.PostHistoryEntries,
        RANK() OVER (ORDER BY um.PostsCreated DESC) AS ActivityRank
    FROM 
        UserMetrics um
    WHERE 
        um.PostsCreated > 0
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate AS ClosureDate,
        pt.Name AS ClosedPostType,
        COUNT(*) AS ClosureReasons 
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        ph.PostHistoryTypeId = 10  -- Post Closed
    GROUP BY 
        ph.PostId, ph.UserDisplayName, ClosureDate, ClosedPostType
),
FinalReport AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        up.UpvotesReceived,
        up.DownvotesReceived,
        up.PostsCreated,
        CASE 
            WHEN m.UserId IS NOT NULL THEN 'Active User'
            ELSE 'Standard User'
        END AS UserType,
        cp.ClosureReasons
    FROM 
        UserMetrics up
    LEFT JOIN 
        MostActiveUsers m ON up.UserId = m.UserId
    LEFT JOIN 
        ClosedPosts cp ON cp.UserDisplayName = up.DisplayName
)
SELECT 
    fr.DisplayName,
    fr.Reputation,
    fr.UpvotesReceived,
    fr.DownvotesReceived,
    fr.PostsCreated,
    fr.UserType,
    COALESCE(fr.ClosureReasons, 0) AS ClosureReasons
FROM 
    FinalReport fr 
ORDER BY 
    fr.Reputation DESC, 
    fr.UpvotesReceived DESC
LIMIT 100;
