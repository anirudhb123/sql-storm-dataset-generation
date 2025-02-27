WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate ASC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(p.Tags, '>')) AS TagName,
        COUNT(*) AS TagPostCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 10
),
PostHistoryCloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes cr ON cr.Id = (ph.Comment::json->>'CloseReasonId')::smallint
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Close and Reopen events
    GROUP BY 
        ph.PostId
)
SELECT 
    au.UserId,
    au.DisplayName,
    au.Reputation,
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    pt.TagPostCount,
    COALESCE(ph.CloseReasons, 'No closure reasons') AS RecentCloseReasons,
    CASE 
        WHEN rp.PostRank = 1 THEN 'Top Post'
        WHEN rp.PostRank <= 5 THEN 'Top 5 Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    ActiveUsers au
JOIN 
    RankedPosts rp ON au.UserId = rp.OwnerUserId 
LEFT JOIN 
    PopularTags pt ON pt.TagName IN (SELECT unnest(string_to_array(rp.Tags, '>')))
LEFT JOIN 
    PostHistoryCloseReasons ph ON ph.PostId = rp.PostId
WHERE 
    au.LastPostDate > CURRENT_DATE - INTERVAL '30 days'
    AND (rp.Score > 0 OR (rp.ViewCount > 100 AND rp.CreationDate < CURRENT_DATE - INTERVAL '1 month'))
ORDER BY 
    au.Reputation DESC, rp.Score DESC
LIMIT 50 OFFSET 0;
