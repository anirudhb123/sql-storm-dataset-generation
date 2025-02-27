WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(MONTH, -12, GETDATE())
), 
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(ps.Score), 0) AS TotalScore,
        AVG(COALESCE(ph.VoteCount, 0)) AS AvgVoteCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (
            SELECT 
                PostId, 
                COUNT(*) AS VoteCount 
            FROM 
                Votes 
            GROUP BY 
                PostId
        ) ph ON p.Id = ph.PostId
    GROUP BY 
        u.Id, u.DisplayName
), 
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserId AS CloserUserId,
        p.Title AS PostTitle,
        p.OwnerDisplayName
    FROM 
        PostHistory ph
    INNER JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId = 10
),
HighScoreUsers AS (
    SELECT 
        UserId, 
        DisplayName 
    FROM 
        UserStats 
    WHERE 
        TotalScore > 100
)

SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalPosts,
    us.TotalAnswers,
    us.TotalScore,
    us.AvgVoteCount,
    rp.Title AS LatestPostTitle,
    COALESCE(cp.PostTitle, 'N/A') AS ClosedPostTitle,
    cp.CreationDate AS ClosedPostDate,
    CASE 
        WHEN us.TotalAnswers > 10 THEN 'High Engagement'
        ELSE 'Moderate Engagement'
    END AS EngagementLevel
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId AND rp.PostRank = 1
LEFT JOIN 
    ClosedPosts cp ON us.UserId = cp.CloserUserId
WHERE 
    us.TotalPosts > 0
ORDER BY 
    us.TotalScore DESC;

