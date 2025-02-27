WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryAggregated AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        MAX(ph.CreationDate) AS LastActivity
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),
PostAnalysis AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        ub.BadgeCount,
        ub.BadgeNames,
        COALESCE(pas.HistoryTypes, 'No history') AS HistoryTypes,
        pas.LastActivity
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    LEFT JOIN 
        PostHistoryAggregated pas ON rp.PostId = pas.PostId
    WHERE 
        rp.UserRank <= 3 -- Top 3 posts per user
)

SELECT 
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.Score,
    pa.ViewCount,
    pa.AnswerCount,
    pa.BadgeCount,
    pa.BadgeNames,
    pa.HistoryTypes,
    pa.LastActivity
FROM 
    PostAnalysis pa
WHERE 
    (pa.BadgeCount = 0 OR pa.BadgeCount > 2) -- Edge case: either no badges or more than 2 badges
    AND pa.ViewCount > (
        SELECT 
            AVG(ViewCount) 
        FROM 
            Posts 
        WHERE 
            CreationDate >= NOW() - INTERVAL '1 year'
    ) -- Only include posts with above-average views
ORDER BY 
    pa.Score DESC, pa.ViewCount ASC -- Score descending, ViewCount ascending for bizarre ranking semantics

UNION ALL 

SELECT 
    -1 AS PostId, 
    'Aggregation Summary' AS Title,
    NULL AS CreationDate,
    COUNT(*) AS Score, 
    SUM(ViewCount) AS ViewCount,
    SUM(AnswerCount) AS AnswerCount,
    NULL AS BadgeCount,
    'N/A' AS BadgeNames,
    'Summary of the Posts' AS HistoryTypes,
    NULL AS LastActivity
FROM 
    PostAnalysis

ORDER BY 
    PostId;
