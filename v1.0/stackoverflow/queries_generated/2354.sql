WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0 
    GROUP BY 
        p.Id, u.DisplayName
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        ARRAY_AGG(DISTINCT cr.Name) AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Author,
    rp.Score,
    COALESCE(cpr.CloseReasons, '{}') AS CloseReasons,
    rp.CommentCount
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPostReasons cpr ON rp.Id = cpr.PostId
WHERE 
    rp.rn = 1 OR rp.Score > 50
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC
LIMIT 10;

SELECT 
    TagId, COUNT(*) AS PostCount
FROM (
    SELECT 
        (UNNEST(string_to_array(substring(Tags, 2, length(Tags) - 2), '><'))))::int AS TagId
    FROM 
        Posts
) AS TagArray
GROUP BY 
    TagId
HAVING 
    COUNT(*) > 5;

WITH FrequentUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COUNT(*) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(*) > 10
)
SELECT 
    fu.DisplayName,
    fu.PostCount,
    ba.Name AS BadgeName
FROM 
    FrequentUsers fu
LEFT JOIN 
    Badges ba ON fu.Id = ba.UserId AND ba.Class = 1
WHERE 
    ba.Name IS NOT NULL
ORDER BY 
    fu.PostCount DESC;
