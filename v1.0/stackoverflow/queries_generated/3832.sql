WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
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
PostAnalytics AS (
    SELECT 
        p.Id,
        p.Title,
        COALESCE(u.DisplayName, 'Deleted User') AS UserName,
        r.Score,
        r.ViewCount,
        COALESCE(b.BadgeCount, 0) AS UserBadgeCount
    FROM 
        RankedPosts r
    LEFT JOIN 
        Users u ON r.AcceptedAnswerId = u.Id
    LEFT JOIN 
        UserBadges b ON u.Id = b.UserId
    WHERE 
        r.rn = 1
)
SELECT 
    pa.Id,
    pa.Title,
    pa.UserName,
    pa.Score,
    pa.ViewCount,
    pa.UserBadgeCount
FROM 
    PostAnalytics pa
WHERE 
    pa.UserBadgeCount > (
        SELECT 
            AVG(UserBadgeCount)
        FROM 
            UserBadges
    )
ORDER BY 
    pa.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

WITH RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY 
        v.PostId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    COALESCE(rv.VoteCount, 0) AS TotalVotes,
    COALESCE(rv.UpVotes, 0) AS UpVotes,
    COALESCE(rv.DownVotes, 0) AS DownVotes
FROM 
    Posts p
LEFT JOIN 
    RecentVotes rv ON p.Id = rv.PostId
WHERE 
    p.AcceptedAnswerId IS NOT NULL
  AND 
    (p.Score + COALESCE(rv.UpVotes, 0) - COALESCE(rv.DownVotes, 0)) > 0
ORDER BY 
    p.Score DESC, 
    TotalVotes DESC;

SELECT 
    pt.Id AS PostTypeId,
    pt.Name AS PostTypeName,
    COUNT(p.Id) AS PostCount,
    SUM(COALESCE(v.VoteCount, 0)) AS TotalVotes
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON pt.Id = p.PostTypeId
LEFT JOIN 
    (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
GROUP BY 
    pt.Id, pt.Name
HAVING 
    COUNT(p.Id) > 10
ORDER BY 
    TotalVotes DESC;
