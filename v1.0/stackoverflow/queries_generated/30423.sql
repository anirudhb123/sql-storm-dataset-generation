WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) -- Only Questions & Answers
),
HighScorePosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        Users.DisplayName AS OwnerName,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        RankedPosts rp
    JOIN 
        Users ON rp.PostId = Users.Id
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    WHERE 
        rp.rn = 1 -- Get the latest post for each user
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, Users.DisplayName
),
FilteredPosts AS (
    SELECT 
        p.PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(b.Class, 0) AS BadgeClass,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS OverallRank
    FROM 
        HighScorePosts p
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId AND b.Class = 1 -- Gold Badge
),
TopPosts AS (
    SELECT 
        *,
        CASE 
            WHEN BadgeClass > 0 THEN 'With Gold Badge'
            ELSE 'No Badge'
        END AS BadgeStatus
    FROM 
        FilteredPosts
    WHERE 
        OverallRank <= 10
)
SELECT 
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.BadgeStatus,
    COALESCE(NULLIF(tp.CommentCount, 0), 'No Comments') AS CommentStatus
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;

-- Outer joins retrieve any comments count, badge types, and filter out the top posts showcasing detailed statistics.
-- The use of window functions helps in ranking and partitioning posts effectively across various criteria.
