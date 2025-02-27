WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rnk
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
LatestBadges AS (
    SELECT 
        u.Id AS UserId,
        b.Name AS BadgeName,
        b.Class,
        RANK() OVER (PARTITION BY u.Id ORDER BY b.Date DESC) AS badge_rnk
    FROM 
        Users u
    JOIN 
        Badges b ON u.Id = b.UserId
),
FilteredUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    fu.DisplayName,
    lp.Title,
    lp.ViewCount,
    lp.CreationDate,
    lb.BadgeName,
    lb.Class,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(vs.UpVotes) AS TotalUpVotes,
    SUM(vs.DownVotes) AS TotalDownVotes
FROM 
    FilteredUsers fu
JOIN 
    RankedPosts lp ON fu.Id = lp.OwnerUserId AND lp.rnk = 1
LEFT JOIN 
    LatestBadges lb ON fu.Id = lb.UserId AND lb.badge_rnk = 1
LEFT JOIN 
    Comments c ON lp.Id = c.PostId
LEFT JOIN 
    (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) vs ON lp.Id = vs.PostId
WHERE 
    lp.ViewCount > 100
GROUP BY 
    fu.DisplayName, lp.Title, lp.ViewCount, lp.CreationDate, lb.BadgeName, lb.Class
ORDER BY 
    TotalUpVotes DESC, lp.ViewCount DESC
LIMIT 50;
