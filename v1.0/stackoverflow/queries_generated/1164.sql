WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate ASC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(rp.ViewCount, 0)) AS TotalViews,
        RANK() OVER (ORDER BY SUM(COALESCE(rp.ViewCount, 0)) DESC) AS ViewsRank
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    u.Reputation,
    tu.TotalViews,
    tu.ViewsRank,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id) AS BadgeCount,
    (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM Posts p 
     JOIN STRING_TO_ARRAY(p.Tags, ',') AS t ON t IS NOT NULL 
     WHERE p.OwnerUserId = u.Id) AS FavoriteTags
FROM 
    Users u
JOIN 
    TopUsers tu ON u.Id = tu.UserId
WHERE 
    u.Reputation > 1000
ORDER BY 
    tu.ViewsRank, u.Reputation DESC
LIMIT 10;

WITH RelevantTags AS (
    SELECT 
        DISTINCT t.TagName
    FROM 
        Posts p 
    JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        p.AcceptedAnswerId IS NOT NULL
    AND 
        p.Score > 0
),
AllPosts AS (
    SELECT 
        p.*,
        CASE 
            WHEN EXISTS (SELECT 1 FROM PostHistory ph WHERE ph.PostId = p.Id AND ph.PostHistoryTypeId = 10) THEN 'Closed' 
            ELSE 'Open' 
        END AS PostStatus
    FROM 
        Posts p
)
SELECT 
    ap.Id,
    ap.Title,
    ap.PostStatus,
    rt.TagName
FROM 
    AllPosts ap
LEFT JOIN 
    RelevantTags rt ON ap.Tags LIKE '%' || rt.TagName || '%'
WHERE 
    ap.LastActivityDate IS NOT NULL
AND 
    (ap.Score > 10 OR ap.ViewCount > 100)
ORDER BY 
    ap.CreationDate DESC;
