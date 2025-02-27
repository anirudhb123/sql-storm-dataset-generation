
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
        AVG(ISNULL(p.AnswerCount, 0)) AS AvgAnswers,
        RANK() OVER (ORDER BY SUM(p.ViewCount) DESC) AS ViewRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
CloseReasonCounts AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS ClosedPostCount,
        SUM(CASE WHEN ph.Comment IS NOT NULL THEN 1 ELSE 0 END) AS CommentedClosedPosts
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10  
    GROUP BY 
        ph.UserId
),
CombinedStats AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.PostCount,
        ups.TotalViews,
        ups.TotalScore,
        ups.AvgAnswers,
        ISNULL(crc.ClosedPostCount, 0) AS ClosedPostCount,
        ISNULL(crc.CommentedClosedPosts, 0) AS CommentedClosedPosts,
        CASE 
            WHEN ups.ViewRank <= 10 THEN 'Top User'
            ELSE 'Regular User'
        END AS UserType
    FROM 
        UserPostStats ups
    LEFT JOIN 
        CloseReasonCounts crc ON ups.UserId = crc.UserId
),
InactiveUserPostCount AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS InactivePostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.CreationDate < DATEADD(YEAR, -1, '2024-10-01 12:34:56') 
    WHERE 
        u.LastAccessDate < DATEADD(YEAR, -1, '2024-10-01 12:34:56')
    GROUP BY 
        u.Id
)
SELECT 
    cs.UserId,
    cs.DisplayName,
    cs.PostCount,
    cs.TotalViews,
    cs.TotalScore,
    cs.AvgAnswers,
    cs.ClosedPostCount,
    cs.CommentedClosedPosts,
    ISNULL(iup.InactivePostCount, 0) AS InactivePostCount
FROM 
    CombinedStats cs
LEFT JOIN 
    InactiveUserPostCount iup ON cs.UserId = iup.UserId
WHERE 
    cs.TotalScore > 10 OR cs.ClosedPostCount > 0
ORDER BY 
    cs.TotalScore DESC, cs.PostCount DESC;
