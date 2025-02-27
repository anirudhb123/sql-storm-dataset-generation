WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
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
PopularTags AS (
    SELECT 
        t.TagName,
        SUM(c.ViewCount) AS TotalViews
    FROM 
        Posts p
    JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN 
        Comments c ON c.PostId = p.Id
    GROUP BY 
        t.TagName
    ORDER BY 
        TotalViews DESC
    LIMIT 10
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        pht.Name AS PostHistoryType,
        u.DisplayName AS UserDisplayName
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    LEFT JOIN 
        Users u ON ph.UserId = u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    ur.Reputation,
    ur.BadgeCount,
    pt.TotalViews,
    ph.UserDisplayName AS LastEditor,
    ph.CreationDate AS LastEditDate,
    ph.PostHistoryType
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
LEFT JOIN 
    PostHistoryDetails ph ON rp.PostId = ph.PostId AND ph.CreationDate = (
        SELECT MAX(CreationDate) 
        FROM PostHistory WHERE PostId = rp.PostId
    )
JOIN 
    PopularTags pt ON rp.Title LIKE '%' || pt.TagName || '%'
WHERE 
    ur.Reputation > 1000 -- Only highly reputed users
    AND rp.rn = 1 -- Latest question for each user
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
