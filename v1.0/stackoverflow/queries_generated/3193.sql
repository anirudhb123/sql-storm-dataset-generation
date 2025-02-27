WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COALESCE(p.Score, 0) DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id
), UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), PostEngagement AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        ub.TotalBadges,
        ub.BadgeNames
    FROM 
        RankedPosts rp
    JOIN 
        UserBadges ub ON rp.PostId IN (
          SELECT 
            p.Id
          FROM 
            Posts p
          WHERE 
            p.OwnerUserId = rp.PostId
        )
    WHERE 
        rp.CommentCount > 0 OR rp.UpVotes > rp.DownVotes
)
SELECT 
    pe.PostId,
    pe.Title,
    COALESCE(pe.CommentCount, 0) AS CommentCount,
    COALESCE(pe.UpVotes, 0) - COALESCE(pe.DownVotes, 0) AS NetVotes,
    CASE 
        WHEN pe.TotalBadges > 0 THEN pe.BadgeNames 
        ELSE 'No Badges' 
    END AS UserBadges
FROM 
    PostEngagement pe
ORDER BY 
    NetVotes DESC, 
    pe.CommentCount DESC
LIMIT 10;
