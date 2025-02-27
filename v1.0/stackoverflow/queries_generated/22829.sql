WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS RankScore,
        ARRAY_AGG(t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.WikiPostId = p.Id OR t.ExcerptPostId = p.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS UpVotes, -- assuming 2 is UpMod
        SUM(COALESCE(v.VoteTypeId = 3, 0)) AS DownVotes  -- assuming 3 is DownMod
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.CreationDate < CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount,
        MIN(ph.CreationDate) AS FirstChange,
        MAX(ph.CreationDate) AS LastChange,
        COUNT(CASE WHEN ph.UserId IS NULL THEN 1 END) AS AnonymousEdits
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '3 months'
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        SUM(u.Reputation) AS TotalReputation,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation IS NOT NULL
    GROUP BY 
        u.Id
)
SELECT 
    up.DisplayName,
    up.TotalPosts,
    up.UpVotes,
    up.DownVotes,
    phs.HistoryCount,
    phs.FirstChange,
    phs.LastChange,
    urep.TotalReputation,
    urep.BadgeCount,
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.Tags
FROM 
    UserActivity up
JOIN 
    PostHistorySummary phs ON phs.PostId = up.UserId -- assuming a relation exists, otherwise adjust to align the relationships correctly
JOIN 
    UserReputation urep ON up.UserId = urep.UserId
LEFT JOIN 
    RankedPosts rp ON rp.PostId = phs.PostId
WHERE 
    urep.TotalReputation > 1000
AND 
    phs.HistoryCount >= 3
ORDER BY 
    rp.RankScore, up.TotalPosts DESC
LIMIT 100;
