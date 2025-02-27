WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS Upvotes,
        SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS Downvotes,
        CASE 
            WHEN SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id) IS NULL THEN 'No Votes'
            WHEN SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id) IS NULL THEN 'Only Upvotes'
            ELSE 'Mixed Votes'
        END AS VoteSummary
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(MONTH, -1, GETDATE()) AND
        (p.Tags IS NOT NULL AND p.Tags LIKE '%SQL%')
),
RecentBadges AS (
    SELECT 
        b.UserId,
        MAX(b.CreationDate) AS LastBadgeDate,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Date >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY 
        b.UserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = u.Id) AS PostCount,
        (SELECT COUNT(*) FROM Comments WHERE UserId = u.Id) AS CommentCount
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rb.LastBadgeDate,
    rb.BadgeNames,
    ur.Reputation,
    ur.PostCount,
    ur.CommentCount,
    rp.RankByScore,
    rp.VoteSummary,
    CASE 
        WHEN rp.CommentCount > 0 THEN 'Has Comments'
        ELSE 'No Comments'
    END AS CommentStatus,
    CASE 
        WHEN ur.Reputation IS NULL THEN 'Unrecognized User'
        ELSE 'Known User'
    END AS UserStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentBadges rb ON rp.PostId = rb.UserId
JOIN 
    UserReputation ur ON rp.PostId = ur.UserId
WHERE 
    rp.RankByScore <= 5
ORDER BY 
    rp.Score DESC, rb.LastBadgeDate DESC
OPTION (RECOMPILE);
