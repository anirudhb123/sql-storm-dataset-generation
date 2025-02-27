WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COUNT(p.Id) FILTER (WHERE p.OwnerUserId IS NOT NULL) AS TotalPosts,
        COUNT(c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    GROUP BY 
        u.Id, u.Reputation
),

RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '6 months'
)

SELECT 
    u.DisplayName,
    u.Reputation,
    u.TotalBounties,
    pah.PostId,
    pah.HistoryRank,
    COUNT(DISTINCT p.Id) FILTER (WHERE p.ViewCount > 100) AS HighViewPosts,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsAssigned
FROM 
    UserActivity u
LEFT JOIN 
    RankedPosts rp ON rp.Rank <= 10
LEFT JOIN 
    RecentPostHistory pah ON pah.PostId = rp.PostId AND pah.HistoryRank = 1
LEFT JOIN 
    Posts p ON p.Id = rp.PostId
LEFT JOIN 
    LATERAL (SELECT 
                  UNNEST(string_to_array(p.Tags, '><')) AS TagName
              ) t ON TRUE
GROUP BY 
    u.DisplayName, 
    u.Reputation, 
    u.TotalBounties, 
    pah.PostId, 
    pah.HistoryRank
HAVING 
    COUNT(DISTINCT p.Id) FILTER (WHERE p.Score > 0) > 5
ORDER BY 
    u.Reputation DESC, 
    HighViewPosts DESC NULLS LAST;
