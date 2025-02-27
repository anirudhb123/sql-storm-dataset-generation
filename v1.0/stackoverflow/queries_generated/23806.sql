WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 /* Only Questions */
      AND 
        p.Score > 0
),
LastActivity AS (
    SELECT 
        p.Id AS PostId,
        MAX(p.LastActivityDate) AS LastActivityDate
    FROM 
        Posts p
    GROUP BY 
        p.Id
),
UserWithBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(u.Reputation) AS HighestReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    INNER JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
),
PostsWithLinks AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS LinkCount
    FROM 
        PostLinks pl
    WHERE 
        pl.LinkTypeId = 3 /* Duplicates */
    GROUP BY 
        pl.PostId
)

SELECT 
    u.DisplayName,
    u.WebsiteUrl,
    p.Title,
    p.CreationDate,
    pa.LastActivityDate,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    COALESCE(b.HighestReputation, 0) AS HighestReputation,
    COALESCE(cr.CloseReasons, 'None') AS CloseReasons,
    COALESCE(pl.LinkCount, 0) AS DuplicateLinkCount,
    SUM(p.Score) OVER (PARTITION BY u.Id) AS TotalScore
FROM 
    Users u
LEFT JOIN 
    RankedPosts p ON u.Id = p.OwnerUserId AND p.RowNum = 1
LEFT JOIN 
    LastActivity pa ON p.PostId = pa.PostId
LEFT JOIN 
    UserWithBadges b ON u.Id = b.UserId
LEFT JOIN 
    CloseReasons cr ON p.PostId = cr.PostId
LEFT JOIN 
    PostsWithLinks pl ON p.PostId = pl.PostId
WHERE 
    p.ViewCount > 100
ORDER BY 
    COALESCE(b.HighestReputation, 0) DESC, 
    p.CreationDate DESC
LIMIT 10;

