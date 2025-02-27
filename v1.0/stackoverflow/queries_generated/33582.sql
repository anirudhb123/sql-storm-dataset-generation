WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(CAST(vt.Name AS VARCHAR(50)), 'No Votes') AS VoteType,
        p.AcceptedAnswerId,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate < NOW() - INTERVAL '1 year'
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.RankByScore,
    rp.CommentCount,
    rp.VoteType,
    p.AcceptedAnswerId,
    p2.Title AS AcceptedAnswerTitle,
    u.DisplayName AS PostOwner,
    u.Reputation AS OwnerReputation,
    CASE 
        WHEN rp.OwnerDisplayName IS NULL THEN 'Anonymous'
        ELSE rp.OwnerDisplayName
    END AS PostOwnerDisplayName
FROM 
    RankedPosts rp
LEFT JOIN 
    Posts p ON rp.AcceptedAnswerId = p.Id
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    Posts p2 ON rp.AcceptedAnswerId = p2.Id
WHERE 
    rp.RankByScore <= 5
ORDER BY 
    rp.Score DESC;

WITH RECURSIVE RecentBadges AS (
    SELECT 
        b.UserId,
        b.Name,
        b.Class,
        b.Date,
        1 AS Depth
    FROM 
        Badges b
    WHERE 
        b.Date > NOW() - INTERVAL '30 days'
    
    UNION ALL

    SELECT 
        b.UserId,
        b.Name,
        b.Class,
        b.Date,
        rb.Depth + 1
    FROM 
        Badges b
    INNER JOIN 
        RecentBadges rb ON b.UserId = rb.UserId
    WHERE 
        rb.Depth < 5
)

SELECT DISTINCT
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(rb.Name) AS BadgeCount,
    STRING_AGG(rb.Name, ', ') AS BadgeNames
FROM 
    Users u
LEFT JOIN 
    RecentBadges rb ON u.Id = rb.UserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    BadgeCount DESC;
