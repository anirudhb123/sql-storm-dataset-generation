WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        ub.UserId,
        b.Name,
        ub.Date,
        DENSE_RANK() OVER (PARTITION BY ub.UserId ORDER BY ub.Date DESC) AS BadgeRank
    FROM 
        Badges ub
    JOIN 
        Users u ON ub.UserId = u.Id
    WHERE 
        u.Reputation > 100
),
TopPosts AS (
    SELECT 
        p.PostId,
        p.Title,
        p.ViewCount,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        RankedPosts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.PostId = c.PostId
    LEFT JOIN 
        Votes v ON p.PostId = v.PostId
    WHERE 
        p.rn <= 5
    GROUP BY 
        p.PostId, p.Title, p.ViewCount, u.DisplayName
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(u.UpVotes) > 100
)
SELECT 
    tp.Title AS PostTitle,
    tp.ViewCount,
    tp.CommentCount,
    tp.OwnerName,
    tu.DisplayName AS TopUser,
    tu.TotalUpVotes,
    tu.TotalDownVotes,
    ub.Name AS UserBadge,
    ub.Date AS BadgeDate
FROM 
    TopPosts tp
JOIN 
    TopUsers tu ON tp.CommentCount = (
        SELECT 
            MAX(CommentCount) 
        FROM 
            TopPosts tp_sub 
        WHERE 
            tp_sub.ViewCount < tp.ViewCount
    )
LEFT JOIN 
    UserBadges ub ON tu.UserId = ub.UserId AND ub.BadgeRank = 1
WHERE 
    tp.ViewCount IS NOT NULL
ORDER BY 
    tp.ViewCount DESC, tp.CommentCount DESC
LIMIT 10;
