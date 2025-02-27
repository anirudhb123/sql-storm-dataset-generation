WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.OwnerUserId, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
QuestionTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Tags t ON t.WikiPostId = p.Id
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
)
SELECT 
    up.DisplayName,
    up.Reputation,
    COALESCE(up.TotalBounty, 0) AS TotalBounty,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    qt.Tags
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
LEFT JOIN 
    UserReputation up ON up.UserId = rp.OwnerUserId
LEFT JOIN 
    QuestionTags qt ON qt.PostId = rp.PostId 
WHERE 
    rp.Rank = 1
    AND (up.Reputation >= 1000 OR qt.Tags IS NOT NULL)
ORDER BY 
    up.Reputation DESC, rp.Score DESC;

WITH LatestEdits AS (
    SELECT 
        ph.PostId, 
        ph.UserDisplayName, 
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)
    GROUP BY 
        ph.PostId, ph.UserDisplayName
)
SELECT 
    p.Title,
    p.Id,
    le.UserDisplayName,
    le.LastEditDate
FROM 
    Posts p
JOIN 
    LatestEdits le ON p.Id = le.PostId
WHERE 
    le.LastEditDate > CURRENT_DATE - INTERVAL '1 month'
ORDER BY 
    le.LastEditDate DESC;
