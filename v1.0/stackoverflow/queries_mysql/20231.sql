
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        MAX(b.Date) OVER (PARTITION BY p.OwnerUserId) AS LatestBadge
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
        AND b.Class = 1  
    WHERE 
        p.CreationDate >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 1 YEAR)
        AND p.PostTypeId = 1  
),
FilteredRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.PostRank,
        rp.CommentCount,
        COALESCE(UNIX_TIMESTAMP(rp.LatestBadge), 0) AS BadgeTimestamp
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1 
        OR rp.CommentCount > 5
),
AggregatedVotes AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    f.PostId,
    f.Title,
    f.ViewCount,
    v.UpVoteCount,
    v.DownVoteCount,
    CASE 
        WHEN f.BadgeTimestamp > 0 THEN 'Gold Badge Owner'
        ELSE 'No Gold Badge'
    END AS BadgeStatus
FROM 
    FilteredRankedPosts f
JOIN 
    AggregatedVotes v ON f.PostId = v.PostId
WHERE 
    (v.UpVoteCount - v.DownVoteCount) > 10  
ORDER BY 
    f.ViewCount DESC
LIMIT 10 OFFSET 0;
