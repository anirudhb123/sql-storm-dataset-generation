WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        COALESCE(po.OpenUserCount, 0) AS OpenUserCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS rn,
        DENSE_RANK() OVER (ORDER BY p.CreationDate DESC) AS dr
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(DISTINCT UserId) AS OpenUserCount
        FROM 
            Votes
        WHERE 
            VoteTypeId = 2 -- UpMod
        GROUP BY 
            PostId
    ) po ON po.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts created in the last year
),
UserBadges AS (
    SELECT 
        b.UserId, 
        STRING_AGG(b.Name, ', ') AS badge_names
    FROM 
        Badges b
    WHERE 
        b.Class = 1 -- Gold badges only
    GROUP BY 
        b.UserId
),
PostEditHistory AS (
    SELECT 
        ph.PostId, 
        ph.PostHistoryTypeId, 
        COUNT(*) AS EditCount,
        ARRAY_AGG(DISTINCT ph.UserDisplayName) AS Editors
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Title, Body, Tags edits
    GROUP BY 
        ph.PostId, 
        ph.PostHistoryTypeId
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Score,
        rb.badge_names,
        pe.EditCount,
        pe.Editors
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges rb ON rb.UserId = rp.OwnerUserId
    LEFT JOIN 
        PostEditHistory pe ON pe.PostId = rp.PostId
    WHERE 
        rp.rn <= 5 -- Top 5 posts per PostType
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.badge_names,
    tp.EditCount,
    CASE 
        WHEN tp.EditCount IS NULL THEN 'No edits'
        ELSE tp.Editors::text
    END AS Editors
FROM 
    TopPosts tp
WHERE 
    tp.Score > (SELECT AVG(Score) FROM Posts) -- Only include posts above average score
ORDER BY 
    tp.Score DESC, tp.Title;

-- Additional complexity with correlated subquery and outer join
SELECT 
    p.Id AS PostId,
    p.Title,
    COUNT( DISTINCT c.Id) AS CommentCount,
    COALESCE(MAX(v.BountyAmount), 0) AS MaxBounty,
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM Votes v
            WHERE v.PostId = p.Id
            AND v.VoteTypeId = 12 -- Spam
        ) THEN 'Flagged as Spam'
        ELSE 'Not Flagged'
    END AS SpamStatus
FROM 
    Posts p
LEFT JOIN 
    Comments c ON c.PostId = p.Id
LEFT JOIN 
    Votes v ON v.PostId = p.Id AND v.VoteTypeId IN (8, 9) -- BountyStart, BountyClose
WHERE 
    p.ViewCount > 1000 -- Only popular posts
GROUP BY 
    p.Id, p.Title
HAVING 
    COUNT(c.Id) > 0 -- Posts with at least one comment
ORDER BY 
    SpamStatus, MaxBounty DESC;

-- Final result could provide insights into post activity and engagement metrics over time
