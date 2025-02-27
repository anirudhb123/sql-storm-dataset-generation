WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions only
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.Body,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        rp.Level + 1
    FROM 
        Posts p
    JOIN 
        RecursivePostCTE rp ON p.ParentId = rp.PostId
    WHERE 
        p.PostTypeId = 2 -- Answers only
),
UserStats AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(c.Score, 0)) AS CommentsScore,
        DENSE_RANK() OVER (ORDER BY SUM(COALESCE(p.Score, 0)) DESC) AS ScoreRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    WHERE 
        u.Reputation > 100 -- Only consider users with reputation > 100
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        us.DisplayName,
        us.Reputation,
        us.PostsCount,
        us.TotalScore,
        us.CommentsScore,
        us.ScoreRank
    FROM 
        UserStats us
    WHERE 
        us.ScoreRank <= 10
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        p.Title,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        COUNT(*) AS ChangeCount
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 YEAR' -- Changes in the last year
    GROUP BY 
        ph.PostId, p.Title
)
SELECT 
    pu.DisplayName AS TopUser,
    pu.Reputation AS UserReputation,
    pu.PostsCount AS UserPostsCount,
    pu.TotalScore AS UserTotalScore,
    phd.Title AS PostTitle,
    phd.HistoryTypes AS RecentChanges,
    phd.ChangeCount AS NumberOfChanges,
    ROW_NUMBER() OVER (PARTITION BY pu.DisplayName ORDER BY pu.TotalScore DESC) AS UserRank
FROM 
    TopUsers pu
JOIN 
    PostHistoryDetails phd ON pu.PostsCount > 0 -- Only joining users with posted questions
LEFT JOIN 
    Posts p ON p.OwnerUserId = pu.Id
WHERE 
    phd.ChangeCount > 5 -- Only include posts with significant changes
ORDER BY 
    pu.TotalScore DESC, pu.DisplayName;

