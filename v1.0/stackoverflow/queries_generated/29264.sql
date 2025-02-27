WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.LastActivityDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
TaggedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Author,
        STRING_AGG(TRIM(UNNEST(string_to_array(substring(rp.Body, POSITION('<tags>' IN rp.Body) + 6, POSITION('</tags>' IN rp.Body) - POSITION('<tags>' IN rp.Body) - 6))), ','), ', ') AS Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.CreationDate, rp.ViewCount, rp.Author
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        c.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes c ON ph.Comment::INT = c.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Closed posts
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.ViewCount,
    tp.Author,
    tp.Tags,
    cp.ClosedDate,
    cp.CloseReason,
    ub.BadgeCount
FROM 
    TaggedPosts tp
LEFT JOIN 
    ClosedPosts cp ON tp.PostId = cp.PostId
LEFT JOIN 
    UserBadges ub ON ub.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
ORDER BY 
    tp.ViewCount DESC, tp.CreationDate DESC
LIMIT 10;
