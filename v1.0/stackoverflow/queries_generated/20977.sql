WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE((SELECT AVG(v.BountyAmount) 
                  FROM Votes v 
                  WHERE v.PostId = p.Id AND v.VoteTypeId IN (8, 9)), 0) AS AvgBounty,
        (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
         FROM Tags t 
         WHERE t.Id IN (SELECT unnest(string_to_array(p.Tags, '>'))::int)) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
),
CommentedPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        rn,
        CommentCount,
        AvgBounty,
        Tags
    FROM 
        RankedPosts 
    WHERE 
        CommentCount > 0
),
FinalResults AS (
    SELECT 
        cp.PostId,
        cp.Title,
        cp.CreationDate,
        cp.Score,
        cp.ViewCount,
        CASE 
            WHEN cp.AvgBounty > 0 THEN 'Has Bounty'
            ELSE 'No Bounty'
        END AS BountyStatus,
        cp.Tags
    FROM 
        CommentedPosts cp
    WHERE 
        cp.rn <= 3
)
SELECT 
    f.PostId,
    f.Title,
    f.CreationDate AS PostCreationDate,
    f.Score AS PostScore,
    f.ViewCount AS PostViews,
    f.BountyStatus,
    COALESCE(CAST((SELECT COUNT(*) 
                   FROM Votes v 
                   WHERE v.PostId = f.PostId AND v.VoteTypeId = 2) AS VARCHAR), '0') AS UpvoteCount,
    COALESCE(CAST((SELECT COUNT(*) 
                   FROM Votes v 
                   WHERE v.PostId = f.PostId AND v.VoteTypeId = 3) AS VARCHAR), '0') AS DownvoteCount,
    f.Tags
FROM 
    FinalResults f
LEFT JOIN 
    PostHistory ph ON ph.PostId = f.PostId AND ph.PostHistoryTypeId IN (10, 11, 12)
WHERE 
    ph.Id IS NULL OR ph.CreationDate >= f.CreationDate
ORDER BY 
    f.Score DESC, f.ViewCount DESC;
