WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVotes,
        SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2022-01-01' 
        AND p.Score > 0
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.Id, 
        rp.Title, 
        rp.CreationDate, 
        rp.Score,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.CommentCount > 10 THEN 'Highly Discussed'
            ELSE 'Moderately Discussed'
        END AS DiscussionLevel
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1
),
UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    tp.Title, 
    tp.CreationDate, 
    tp.Score, 
    tp.DiscussionLevel, 
    ub.UserId, 
    ub.BadgeCount,
    CASE 
        WHEN ub.BadgeCount > 3 THEN 'Veteran'
        ELSE 'Newbie'
    END AS UserStatus
FROM 
    TopPosts tp
JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = tp.Id)
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    ub.UserId IS NOT NULL
ORDER BY 
    tp.Score DESC, 
    tp.CreationDate DESC;
