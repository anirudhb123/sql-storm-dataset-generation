WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        COUNT(c.Id) AS CommentCount,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.Body, p.AcceptedAnswerId, u.DisplayName
),
TopUsers AS (
    SELECT 
        OwnerUserId,
        COUNT(PostId) AS PostCount,
        SUM(CommentCount) AS TotalComments
    FROM 
        RankedPosts
    GROUP BY 
        OwnerUserId
    HAVING 
        COUNT(PostId) > 5
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    t.PostCount,
    t.TotalComments,
    COALESCE(b.BadgeNames, 'No badges') AS Badges
FROM 
    Users u
JOIN 
    TopUsers t ON u.Id = t.OwnerUserId
LEFT JOIN 
    UserBadges b ON u.Id = b.UserId
ORDER BY 
    t.PostCount DESC, t.TotalComments DESC
LIMIT 10;
