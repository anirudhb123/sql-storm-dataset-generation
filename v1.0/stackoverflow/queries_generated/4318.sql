WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE(NULLIF(p.Body, ''), '[No Content]') AS BodyContent
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(cr.Name SEPARATOR ', ') AS CloseReasonNames
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment = CAST(cr.Id AS CHAR)
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Only considers close and reopen events
    GROUP BY 
        ph.PostId
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.BodyContent,
    cr.CloseReasonNames,
    us.UpVotes,
    us.DownVotes,
    us.BadgeCount
FROM 
    RankedPosts rp
LEFT JOIN 
    CloseReasons cr ON rp.PostId = cr.PostId
LEFT JOIN 
    UserScores us ON rp.OwnerUserId = us.UserId
WHERE 
    rp.Rank = 1
    AND (rp.Score > 10 OR us.UpVotes > 5)
ORDER BY 
    rp.CreationDate DESC
LIMIT 100;
