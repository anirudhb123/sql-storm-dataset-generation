WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN pht.Name = 'Post Closed' THEN ph.CreationDate END) AS LastClosedDate,
        COUNT(CASE WHEN pht.Name = 'Edit Title' THEN 1 END) AS EditTitleCount,
        COUNT(CASE WHEN pht.Name = 'Edit Body' THEN 1 END) AS EditBodyCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),
RecentPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        DATE_PART('year', AGE(rp.CreationDate)) AS PostAgeYears,
        rps.LastClosedDate,
        rps.EditTitleCount,
        rps.EditBodyCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistorySummary rps ON rp.PostId = rps.PostId
    WHERE 
        rp.UserPostRank = 1 -- Most recent post for each user
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    COALESCE(rp.LastClosedDate, 'Not Closed') AS LastClosedDate,
    rp.EditTitleCount,
    rp.EditBodyCount,
    CASE 
        WHEN rp.PostAgeYears < 1 THEN 'New' 
        WHEN rp.PostAgeYears >= 1 AND rp.PostAgeYears < 2 THEN 'Moderate' 
        ELSE 'Old' 
    END AS AgeCategory,
    CASE 
        WHEN rp.EditBodyCount > 5 THEN 'Frequently Edited'
        ELSE 'Seldom Edited'
    END AS EditActivity
FROM 
    RecentPosts rp
ORDER BY 
    rp.Score DESC, 
    rp.OwnerDisplayName ASC
LIMIT 50;
