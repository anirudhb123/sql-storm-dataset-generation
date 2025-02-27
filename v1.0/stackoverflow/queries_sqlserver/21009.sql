
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, u.Reputation
), 
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Reputation,
        CommentCount,
        UpVotes,
        DownVotes,
        COALESCE(UpVotes, 0) - COALESCE(DownVotes, 0) AS NetVotes
    FROM 
        RankedPosts
    WHERE 
        rn = 1
),
HistoricalBadges AS (
    SELECT 
        b.UserId,
        MIN(b.Date) AS FirstBadgeDate,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Date >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY 
        b.UserId
) 
SELECT 
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    pp.ViewCount,
    pp.Reputation,
    pp.CommentCount,
    pp.NetVotes,
    hb.FirstBadgeDate,
    hb.BadgeCount,
    COALESCE(hb.BadgeNames, 'No Badges') AS BadgeNames
FROM 
    TopPosts pp
LEFT JOIN 
    HistoricalBadges hb ON pp.Reputation > 1000 AND pp.Reputation = hb.UserId
ORDER BY 
    pp.NetVotes DESC,
    pp.ViewCount DESC,
    pp.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
