WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        MAX(p.LastActivityDate) AS LastActivity
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- BountyStart and BountyClose
    WHERE 
        u.CreationDate <= NOW() - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryAgg AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastChange,
        STRING_AGG(DISTINCT pht.Name, ', ') AS ChangeTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '6 months'
    GROUP BY 
        ph.PostId
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.QuestionCount,
    u.TotalBounties,
    u.LastActivity,
    rp.Title,
    rp.CreationDate AS MostRecentQuestionDate,
    COALESCE(ph.HistoryCount, 0) AS ChangesMade,
    COALESCE(ph.LastChange, 'No Changes') AS LastChangeDate,
    COALESCE(ph.ChangeTypes, 'No Changes') AS ChangeHistory
FROM 
    UserActivity u
LEFT JOIN 
    RankedPosts rp ON u.UserId = rp.OwnerUserId AND rp.rn = 1
LEFT JOIN 
    PostHistoryAgg ph ON rp.Id = ph.PostId
ORDER BY 
    u.QuestionCount DESC, 
    u.TotalBounties DESC
LIMIT 100;
