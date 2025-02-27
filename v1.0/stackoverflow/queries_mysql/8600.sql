
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 30 DAY)
),
TagStatistics AS (
    SELECT
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
),
PopularTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        AverageScore,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank
    FROM 
        TagStatistics
    WHERE 
        PostCount >= 5
),
RecentPostHistory AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate, 
        ph.UserDisplayName, 
        ph.Comment, 
        p.Title AS PostTitle
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 7 DAY)
    ORDER BY 
        ph.CreationDate DESC
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    pt.TagName,
    ps.PostCount,
    ps.TotalViews,
    ps.AverageScore,
    rph.CreationDate AS RecentChangeDate,
    rph.UserDisplayName AS EditedBy,
    rph.Comment AS EditComment
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags pt ON rp.Title LIKE CONCAT('%', pt.TagName, '%')
LEFT JOIN 
    TagStatistics ps ON pt.TagName = ps.TagName
LEFT JOIN 
    RecentPostHistory rph ON rp.PostId = rph.PostId
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
