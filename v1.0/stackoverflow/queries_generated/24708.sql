WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        COUNT(DISTINCT v.Id) AS TotalVotes,
        AVG(u.Reputation) OVER () AS AverageReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostActivity AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1
            WHEN ph.PostHistoryTypeId = 24 AND ph.Comment LIKE '%great%' THEN 2
            ELSE 0 
        END AS ActivityType
    FROM 
        PostHistory ph
),
FilteredVotes AS (
    SELECT 
        v.PostId,
        v.VoteTypeId,
        COUNT(*) AS VoteCount
    FROM 
        Votes v
    GROUP BY 
        v.PostId, v.VoteTypeId
),
ClosedPosts AS (
    SELECT 
        p.Id AS ClosedPostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS CloseDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        p.Id
)
SELECT 
    up.UserId,
    u.DisplayName,
    up.PostId,
    up.Title,
    up.Rank AS PostRank,
    ur.Reputation,
    ur.TotalBadges,
    ur.TotalVotes,
    COALESCE(cp.CloseDate, 'No Closure') AS LastCloseDate,
    AVG(pa.ActivityType) AS AverageActivity
FROM 
    RankedPosts up
JOIN 
    Users u ON up.OwnerUserId = u.Id
LEFT JOIN 
    UserReputation ur ON ur.UserId = u.Id
LEFT JOIN 
    ClosedPosts cp ON up.PostId = cp.ClosedPostId
LEFT JOIN 
    PostActivity pa ON up.PostId = pa.PostId
WHERE 
    ur.Reputation >= (SELECT AVG(Reputation) FROM Users) 
    AND up.Rank <= 5
ORDER BY 
    up.Rank, ur.Reputation DESC;
This SQL query performs the following complex operations:

1. **Common Table Expressions (CTEs)** are used to structure the query into segments, improving readability and maintainability.
2. It ranks posts made within the last year by each user.
3. It aggregates user reputations, total badges, and vote counts.
4. It analyzes post histories to identify closed posts and their closure dates, handling various types of activities.
5. It performs an outer join to correlate user reputation and post activity against posts, filtering for high-reputation users.
6. The query selects only the top 5 recent posts per user and orders them by rank and reputation, also providing insights on post closure and activity averages. 

The query's complexity lies in its extensive use of CTEs, window functions, conditional joins, and NULL handling to present a detailed performance benchmark based on user activity and post engagement metrics.
