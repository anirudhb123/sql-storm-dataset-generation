WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        LAG(p.CreationDate) OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate) AS LastPostDate,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsList
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.PostTypeId, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        MAX(u.CreationDate) AS AccountCreationDate
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.Reputation
),
PostHistoryCloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.RankScore,
    u.Reputation,
    u.BadgeCount,
    COALESCE(p.LastPostDate, '2010-01-01'::timestamp) AS LastPostDate,
    p.TagsList,
    COALESCE(cr.CloseReasons, 'No close reasons') AS CloseReasons
FROM 
    RankedPosts p
JOIN 
    UserReputation u ON p.OwnerUserId = u.UserId
LEFT JOIN 
    PostHistoryCloseReasons cr ON p.PostId = cr.PostId
WHERE 
    p.RankScore <= 5 
    AND (u.Reputation > 1000 OR u.BadgeCount > 5)
    AND (p.ViewCount > 50 OR p.Score IS NULL)
ORDER BY 
    p.Score DESC,
    p.CreationDate DESC NULLS LAST
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
