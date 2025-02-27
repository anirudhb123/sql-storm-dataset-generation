WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.ViewCount, p.OwnerUserId
),
RecentBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Date >= NOW() - INTERVAL '1 year'
    GROUP BY 
        b.UserId
),
TotalVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.CommentCount,
    COALESCE(rb.BadgeNames, 'No Badges') AS Badges,
    COALESCE(tv.UpVotes, 0) AS TotalUpVotes,
    COALESCE(tv.DownVotes, 0) AS TotalDownVotes
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentBadges rb ON rp.OwnerUserId = rb.UserId
LEFT JOIN 
    TotalVotes tv ON rp.PostId = tv.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.ViewCount DESC, rp.CreationDate DESC
LIMIT 10;
