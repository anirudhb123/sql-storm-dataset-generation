WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(u.Location, 'Unknown') AS UserLocation,
        COALESCE(b.Class, 0) AS UserBadgeClass
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId AND b.Date = (
            SELECT MAX(Date) 
            FROM Badges 
            WHERE UserId = u.Id
        )
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostComments AS (
    SELECT
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 12)  -- Closed or Deleted
    GROUP BY 
        ph.PostId
),
CombinedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        rp.Score,
        pc.CommentCount,
        cp.LastClosedDate,
        CASE 
            WHEN cp.LastClosedDate IS NOT NULL THEN 'Closed'
            ELSE 'Active'
        END AS PostStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostComments pc ON rp.PostId = pc.PostId
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    WHERE 
        rp.rn = 1  -- Only the latest post by user
)
SELECT 
    cd.PostId,
    cd.Title,
    cd.CreationDate,
    cd.ViewCount,
    cd.AnswerCount,
    cd.Score,
    cd.CommentCount,
    cd.LastClosedDate,
    cd.PostStatus,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    CombinedData cd
LEFT JOIN 
    Posts p ON cd.PostId = p.Id
LEFT JOIN 
    STRING_TO_ARRAY(p.Tags, ',') AS tag_array ON TRUE  -- Using string functions for tags
LEFT JOIN 
    Tags t ON t.Id = tag_array::int  -- Converting string to int for tag ID lookup
WHERE
    cd.PostStatus = 'Active'
GROUP BY 
    cd.PostId, cd.Title, cd.CreationDate, cd.ViewCount, cd.AnswerCount, cd.Score, cd.CommentCount, cd.LastClosedDate, cd.PostStatus
ORDER BY 
    cd.Score DESC NULLS LAST, cd.ViewCount DESC NULLS FIRST
LIMIT 50;
