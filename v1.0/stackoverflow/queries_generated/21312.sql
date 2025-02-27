WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS ViewRank,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS UpVotesCount,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS DownVotesCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),

AggregatedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),

PostActivity AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)

SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalBadges,
    u.PostCount,
    u.TotalViews,
    u.QuestionCount,
    p.Title,
    rp.ViewCount,
    rp.UpVotesCount,
    rp.DownVotesCount,
    pa.LastEditDate,
    pa.HistoryTypes
FROM 
    AggregatedUsers u
JOIN 
    RankedPosts rp ON u.UserId = rp.OwnerUserId
LEFT JOIN 
    PostActivity pa ON rp.PostId = pa.PostId
WHERE 
    (u.TotalViews IS NOT NULL OR u.QuestionCount > 0)
    AND rp.ViewRank <= 5
ORDER BY 
    u.TotalBadges DESC,
    rp.ViewCount DESC,
    pa.LastEditDate DESC
LIMIT 50;

-- This query pulls user statistics alongside the top viewed posts they own within the past year, 
-- also taking into account the edit history and types of edits made on those posts.
-- It uses CTEs to aggregate data and employs window functions to rank posts by views.
