WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        SUM(COALESCE(v.BountyAmount, 0)) OVER (PARTITION BY p.OwnerUserId) AS TotalBounties
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- BountyStart and BountyClose
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
PostHistoryDetail AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.Comment,
        CONVERT(VARCHAR, ph.CreationDate, 101) AS FormattedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) -- Closed, Reopened, Deleted
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS AssociatedPosts
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' + t.TagName + '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(DISTINCT p.Id) > 5
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.PostCount,
    up.TotalViews,
    up.AvgScore,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    NULLIF(rp.TotalBounties, 0) AS TotalBounties,
    pmd.FormattedDate AS HistoryDate,
    (SELECT STRING_AGG(t.TagName, ', ') 
     FROM PopularTags t 
     JOIN Posts p ON p.Tags LIKE '%' + t.TagName + '%'
     WHERE p.Id = rp.PostId) AS RelatedTags
FROM 
    UserStats up
LEFT JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId AND rp.rn = 1
LEFT JOIN 
    PostHistoryDetail pmd ON rp.PostId = pmd.PostId
WHERE 
    up.PostCount > 10
ORDER BY 
    up.TotalViews DESC, up.AvgScore DESC;
