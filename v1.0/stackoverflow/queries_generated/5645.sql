WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId IN (1, 2) -- Only interested in Questions and Answers
        AND p.CreationDate > NOW() - INTERVAL '1 year' -- Last year
),
TopComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    WHERE 
        c.CreationDate > NOW() - INTERVAL '1 year' -- Last year
    GROUP BY 
        c.PostId
),
BadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rc.CommentCount,
        bc.BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        TopComments rc ON rp.PostId = rc.PostId
    LEFT JOIN 
        BadgeCounts bc ON rp.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = bc.UserId)
    WHERE 
        rp.PostRank <= 5 -- Top 5 posts per type
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.Score,
    fr.ViewCount,
    fr.OwnerDisplayName,
    COALESCE(fr.CommentCount, 0) AS CommentCount,
    COALESCE(fr.BadgeCount, 0) AS BadgeCount
FROM 
    FinalResults fr
ORDER BY 
    fr.Score DESC, fr.ViewCount DESC;
