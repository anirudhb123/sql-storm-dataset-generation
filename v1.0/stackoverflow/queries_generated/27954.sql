WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > DATEADD(year, -1, GETDATE()) -- Only consider posts from the last year
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.Score, p.ViewCount, p.CreationDate, p.OwnerUserId
),
FilteredPosts AS (
    SELECT 
        rp.*,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation AS OwnerReputation
    FROM 
        RankedPosts rp
    JOIN 
        Users U ON rp.OwnerUserId = U.Id
    WHERE 
        rp.CommentCount > 5 -- Filter for posts with more than 5 comments
),
BadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    WHERE 
        Class = 1 -- Only Gold badges
    GROUP BY 
        UserId
)
SELECT 
    fp.Title,
    fp.Body,
    fp.Tags,
    fp.Score,
    fp.ViewCount,
    fp.CreationDate,
    fp.CommentCount,
    fp.OwnerDisplayName,
    fp.OwnerReputation,
    COALESCE(bc.BadgeCount, 0) AS GoldBadgeCount
FROM 
    FilteredPosts fp
LEFT JOIN 
    BadgeCounts bc ON fp.OwnerUserId = bc.UserId
ORDER BY 
    fp.Score DESC, fp.ViewCount DESC, fp.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY; -- Limit to 10 top posts
