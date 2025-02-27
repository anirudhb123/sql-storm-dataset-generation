WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT p.Id) AS PostsCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        Reputation,
        Upvotes - Downvotes AS NetVotes,
        PostsCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserStats
    WHERE 
        PostsCount > 0
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        MAX(ph.CreationDate) AS LastCloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
CombinedData AS (
    SELECT 
        tu.UserId,
        tu.DisplayName,
        tu.Reputation,
        tu.NetVotes,
        cp.CloseCount,
        cp.LastCloseDate,
        ROW_NUMBER() OVER (PARTITION BY tu.ReputationRank ORDER BY tu.NetVotes DESC) AS VotesRank
    FROM 
        TopUsers tu
    LEFT JOIN 
        ClosedPosts cp ON EXISTS (
            SELECT 1 FROM Posts p WHERE p.OwnerUserId = tu.UserId AND p.Id = cp.PostId
        )
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    NetVotes,
    COALESCE(CloseCount, 0) AS CloseCount,
    COALESCE(LastCloseDate, '1970-01-01') AS LastCloseDate
FROM 
    CombinedData
WHERE 
    VotesRank <= 5
ORDER BY 
    Reputation DESC, NetVotes DESC;
