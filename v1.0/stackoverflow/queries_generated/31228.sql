WITH RecursiveCTE AS (
    SELECT 
        Id, 
        OwnerUserId,
        Title,
        PostTypeId,
        LastActivityDate,
        Score,
        ViewCount,
        1 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Starting from Questions
    UNION ALL
    SELECT 
        p.Id, 
        p.OwnerUserId,
        p.Title,
        p.PostTypeId,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursiveCTE r ON p.ParentId = r.Id
    WHERE 
        p.PostTypeId = 2  -- Join to Answers
), 
RankedPosts AS (
    SELECT 
        r.Id,
        r.OwnerUserId,
        r.Title,
        r.PostTypeId,
        r.LastActivityDate,
        r.Score,
        r.ViewCount,
        RANK() OVER (PARTITION BY r.OwnerUserId ORDER BY r.Score DESC) AS UserRank,
        COUNT(*) OVER (PARTITION BY r.OwnerUserId) AS PostCount
    FROM 
        RecursiveCTE r
), 
AggUserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(rp.Score) AS TotalScore,
        SUM(rp.ViewCount) AS TotalViews,
        AVG(rp.UserRank) AS AvgPostRank,
        COUNT(rp.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
), 
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS CloseCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    GROUP BY 
        p.Id
), 
FinalOutput AS (
    SELECT 
        a.UserId,
        a.DisplayName,
        COALESCE(a.TotalScore, 0) AS TotalScore,
        COALESCE(a.TotalViews, 0) AS TotalViews,
        COALESCE(a.AvgPostRank, 0) AS AvgPostRank,
        COALESCE(a.PostCount, 0) AS PostCount,
        COALESCE(c.CloseCount, 0) AS ClosedPostCount
    FROM 
        AggUserStats a
    LEFT JOIN 
        ClosedPosts c ON a.UserId = c.PostId
)
SELECT 
    UserId,
    DisplayName,
    TotalScore,
    TotalViews,
    AvgPostRank,
    PostCount,
    ClosedPostCount,
    CASE 
        WHEN TotalScore > 1000 THEN 'High Contributor'
        WHEN TotalScore BETWEEN 500 AND 1000 THEN 'Moderate Contributor'
        ELSE 'New Contributor'
    END AS ContributionLevel
FROM 
    FinalOutput
WHERE 
    PostCount > 5
ORDER BY 
    TotalScore DESC;
