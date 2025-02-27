WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(*) OVER (PARTITION BY p.PostTypeId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
), 
AggregatedUserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    GROUP BY 
        u.Id
),
PostHistoryTypesWithComments AS (
    SELECT 
        ph.PostId,
        ARRAY_AGG(DISTINCT cp.Text) AS Comments,
        ARRAY_AGG(DISTINCT pht.Name) AS HistoryTypes
    FROM 
        PostHistory ph
    LEFT JOIN 
        Comments cp ON ph.PostId = cp.PostId
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    (SELECT 
         u.DisplayName
     FROM 
         Users u
     WHERE 
         u.Id = p.OwnerUserId) AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COALESCE(ps.Comments, '{}') AS RelatedComments,
    COALESCE(ps.HistoryTypes, '{}') AS HistoryTypes,
    CASE 
        WHEN p.ViewCount > 1000 THEN 'Popular'
        ELSE 'Less Popular'
    END AS PopularityStatus,
    AVG(u.Reputation) OVER () AS AvgReputation,
    (SELECT 
         COUNT(*) 
     FROM 
         Posts p2 
     WHERE 
         p2.OwnerUserId = p.OwnerUserId 
         AND p2.Score > p.Score) AS HigherScoreCount,
    (SELECT 
         u2.Reputation
     FROM 
         Users u2
     WHERE 
         u2.Id IN (SELECT DISTINCT b.UserId 
                    FROM Badges b 
                    WHERE b.Date >= NOW() - INTERVAL '1 year') 
     ORDER BY 
         u2.Reputation DESC 
     LIMIT 1) AS TopReputationLastYear
FROM 
    RankedPosts p
JOIN 
    AggregatedUserStats u ON p.OwnerUserId = u.UserId
LEFT JOIN 
    PostHistoryTypesWithComments ps ON p.PostId = ps.PostId
WHERE 
    u.Reputation > (SELECT AVG(Reputation) FROM Users) 
    AND (SELECT COUNT(*) FROM Votes v WHERE v.VoteTypeId IN (2, 3) AND v.PostId = p.PostId) > 10
ORDER BY 
    p.Score DESC, 
    p.ViewCount DESC
LIMIT 50;
