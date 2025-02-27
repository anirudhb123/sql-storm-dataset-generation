WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
), 
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount
    FROM 
        RecentPosts rp
    WHERE 
        rp.Score >= 0
        AND rp.rn = 1
), 
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), 
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ub.BadgeCount,
        ROW_NUMBER() OVER (ORDER BY ub.BadgeCount DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        u.Reputation > 1000
)
SELECT 
    fp.Title AS PostTitle,
    fp.CommentCount,
    t.DisplayName AS TopUser,
    tb.BadgeNames,
    COALESCE(MIN(ph.CreationDate), 'No History') AS FirstPostEdit
FROM 
    FilteredPosts fp
LEFT JOIN 
    Posts ph ON fp.PostId = ph.Id AND ph.LastEditDate IS NOT NULL
LEFT JOIN 
    TopUsers t ON fp.Score = t.UserRank
LEFT JOIN 
    UserBadges tb ON t.UserId = tb.UserId
WHERE 
    t.UserRank <= 10
GROUP BY 
    fp.Title, fp.CommentCount, t.DisplayName, tb.BadgeNames
ORDER BY 
    fp.CommentCount DESC, fp.Score DESC
WITH ROLLUP; -- Including rollup to display overall totals
