WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(u.Reputation) AS MaxReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY 
        ph.PostId
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        UNNEST(STRING_TO_ARRAY(p.Tags, '><')) AS t(TagName) ON TRUE
    GROUP BY 
        p.Id
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.ViewCount,
    pp.Score,
    pp.Rank,
    ur.BadgeCount,
    ur.MaxReputation,
    ct.LastClosedDate,
    pt.Tags,
    COALESCE(NULLIF(ur.MaxReputation, 0), 'No Reputation') AS ReputationStatus
FROM 
    RankedPosts pp
LEFT JOIN 
    UserReputation ur ON pp.OwnerUserId = ur.UserId
LEFT JOIN 
    ClosedPosts ct ON pp.PostId = ct.PostId
LEFT JOIN 
    PostTags pt ON pp.PostId = pt.PostId
WHERE 
    pp.Rank <= 5
    AND COALESCE(ct.LastClosedDate, NOW()) >= NOW() - INTERVAL '6 months'
ORDER BY 
    pp.Score DESC, pp.CreationDate DESC;
