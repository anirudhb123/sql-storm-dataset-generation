WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstEditDate,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId = 10) AS CloseCount,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId = 11) AS ReopenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS TagCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        t.TagName
    ORDER BY 
        TagCount DESC
    LIMIT 5
)
SELECT 
    up.DisplayName AS UserName,
    up.Reputation,
    up.BadgeCount,
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    ph.FirstEditDate,
    ph.CloseCount,
    ph.ReopenCount,
    tt.TagName,
    tt.TagCount
FROM 
    RecentPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
JOIN 
    UserReputation ur ON up.Id = ur.UserId
LEFT JOIN 
    PostHistoryDetails ph ON rp.PostId = ph.PostId
LEFT JOIN 
    TopTags tt ON tt.TagName = ANY(string_to_array(rp.Tags, ','))
WHERE 
    rp.rn = 1 
    AND ur.Reputation > 100 
    AND (ph.CloseCount > 0 OR ph.ReopenCount > 0)
ORDER BY 
    ur.Reputation DESC,
    rp.ViewCount DESC;

