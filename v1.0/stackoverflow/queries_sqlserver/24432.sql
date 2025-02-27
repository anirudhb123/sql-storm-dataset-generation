
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate < DATEADD(YEAR, -1, '2024-10-01 12:34:56') 
        AND p.Score > 0
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(ISNULL(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 10 
        AND SUM(ISNULL(v.BountyAmount, 0)) > 0
),
Mortuary AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate, 
        ph.Comment AS CloseReason 
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
        AND ph.CreationDate >= DATEADD(YEAR, -2, '2024-10-01 12:34:56')
),
FinalReport AS (
    SELECT 
        mu.UserId,
        mu.DisplayName,
        rp.PostId,
        rp.Title,
        rp.CreationDate AS PostCreationDate,
        rp.ViewCount,
        rp.Score,
        ISNULL(m.CloseReason, 'N/A') AS CloseReason,
        mu.TotalBounty,
        CASE 
            WHEN mu.PostCount >= 20 THEN 'Frequent Contributor'
            ELSE 'Occasional Contributor' 
        END AS ContributorType 
    FROM 
        MostActiveUsers mu
    JOIN 
        RankedPosts rp ON mu.UserId = rp.OwnerUserId
    LEFT JOIN 
        Mortuary m ON rp.PostId = m.PostId
)
SELECT 
    UserId,
    DisplayName,
    COUNT(PostId) AS ActivePostCount,
    SUM(ViewCount) AS TotalViews,
    AVG(Score) AS AverageScore,
    STRING_AGG(DISTINCT CloseReason, ', ') AS CloseReasons,
    ContributorType
FROM 
    FinalReport
GROUP BY 
    UserId, DisplayName, ContributorType
ORDER BY 
    TotalViews DESC, AverageScore DESC 
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
