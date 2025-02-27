WITH RECURSIVE UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName

    UNION ALL

    SELECT 
        up.UserId,
        up.DisplayName,
        up.PostCount + 1
    FROM 
        UserPostCounts up
    JOIN Posts p ON up.UserId = p.OwnerUserId
    WHERE 
        up.PostCount < 100 -- Limit for recursive counting
),

MostActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount
    FROM 
        UserPostCounts
    WHERE 
        PostCount > 10 -- Ensures we only include active users
),

PostVoteCount AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p 
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),

PostHistoryStats AS (
    SELECT 
        ph.PostId,
        p.Title,
        COUNT(ph.Id) AS HistoryChangeCount,
        STRING_AGG(DISTINCT pht.Name, ', ') AS ChangeTypes
    FROM 
        PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    JOIN Posts p ON ph.PostId = p.Id
    GROUP BY ph.PostId, p.Title
)

SELECT 
    u.DisplayName AS UserDisplayName,
    u.Reputation,
    u.CreationDate,
    COALESCE(pwc.PostCount, 0) AS TotalPosts,
    COALESCE(pvc.PostId, 0) AS ModifiedPostId,
    COALESCE(pvc.VoteCount, 0) AS VoteCount,
    COALESCE(pHistory.HistoryChangeCount, 0) AS HistoryChangeCount,
    COALESCE(pHistory.ChangeTypes, 'None') AS RecentChangeTypes
FROM 
    Users u
LEFT JOIN MostActiveUsers mau ON u.Id = mau.UserId
LEFT JOIN UserPostCounts pwc ON u.Id = pwc.UserId
LEFT JOIN PostVoteCount pvc ON pvc.PostId IN (
    SELECT 
        Posts.Id 
    FROM 
        Posts 
    WHERE 
        Posts.OwnerUserId = u.Id
)
LEFT JOIN PostHistoryStats pHistory ON pHistory.PostId IN (
    SELECT 
        Posts.Id 
    FROM 
        Posts 
    WHERE 
        Posts.OwnerUserId = u.Id
)
WHERE 
    u.Reputation IS NOT NULL
ORDER BY 
    u.Reputation DESC;
