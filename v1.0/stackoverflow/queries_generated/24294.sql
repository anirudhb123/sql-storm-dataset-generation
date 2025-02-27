WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY u.CreationDate DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
),
MostActiveTags AS (
    SELECT 
        unnest(string_to_array(p.Tags, '><')) AS TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        TagName
    ORDER BY 
        PostCount DESC 
    LIMIT 10
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
    HAVING 
        COUNT(b.Id) > 1
),
SuspiciousPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(ph.EditCount, 0) AS EditCount,
        CASE 
            WHEN COALESCE(c.CommentCount, 0) = 0 AND COALESCE(ph.EditCount, 0) > 5 THEN 'Potentially Abandoned'
            ELSE 'Active'
        END AS PostStatus
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(Id) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(Id) AS EditCount
        FROM 
            PostHistory
        WHERE 
            PostHistoryTypeId IN (4, 5, 6)
        GROUP BY 
            PostId
    ) ph ON p.Id = ph.PostId
    WHERE 
        p.Score < 0 OR p.ViewCount < 10
)
SELECT 
    u.DisplayName,
    u.Reputation,
    m.TagName,
    b.BadgeCount,
    b.BadgeNames,
    sp.Title AS SuspiciousPostTitle,
    sp.PostStatus
FROM 
    RankedUsers u
INNER JOIN 
    MostActiveTags m ON m.TagName IN (SELECT unnest(string_to_array((SELECT Tags FROM Posts WHERE OwnerUserId = u.UserId LIMIT 1), '><')))
LEFT JOIN 
    UserBadges b ON u.UserId = b.UserId
LEFT JOIN 
    SuspiciousPosts sp ON sp.Id IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.UserId)
WHERE 
    u.UserRank = 1
ORDER BY 
    u.Reputation DESC, b.BadgeCount DESC NULLS LAST;

