
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        pt.Name AS PostType,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01')
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        LISTAGG(b.Name, ', ') WITHIN GROUP (ORDER BY b.Name) AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
RecentVotes AS (
    SELECT
        v.PostId,
        vt.Name AS VoteType,
        COUNT(*) AS VoteCount
    FROM
        Votes v
    JOIN
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE
        v.CreationDate >= DATEADD(day, -30, '2024-10-01')
    GROUP BY
        v.PostId, vt.Name
),
PostVoteSummary AS (
    SELECT 
        r.Id,
        r.Title,
        r.CreationDate,
        r.ViewCount,
        r.Score,
        COALESCE(rv.VoteCount, 0) AS Upvotes,
        COALESCE(DOWN.VoteCount, 0) AS Downvotes,
        COALESCE(ub.BadgeCount, 0) AS UserBadgeCount,
        COALESCE(ub.BadgeNames, 'No Badges') AS UserBadges
    FROM 
        RankedPosts r
    LEFT JOIN 
        RecentVotes rv ON r.Id = rv.PostId AND rv.VoteType = 'UpMod'
    LEFT JOIN 
        RecentVotes DOWN ON r.Id = DOWN.PostId AND DOWN.VoteType = 'DownMod'
    LEFT JOIN 
        Users u ON r.Id = u.Id
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        r.Rank <= 10
)
SELECT 
    p.Id,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    p.Upvotes,
    p.Downvotes,
    p.UserBadgeCount,
    p.UserBadges
FROM 
    PostVoteSummary p
ORDER BY 
    p.Score DESC, p.ViewCount DESC;
