WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagsList
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    LEFT JOIN 
        Tags t ON t.Id = ANY(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')::int[])
    GROUP BY 
        p.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.RankScore,
        rp.CommentCount,
        rp.TotalBounty,
        rp.TagsList,
        cp.FirstClosedDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    WHERE 
        rp.RankScore <= 3
    ORDER BY 
        rp.Score DESC
)
SELECT 
    tp.*,
    CASE 
        WHEN tp.FirstClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    CASE 
        WHEN tp.TotalBounty > 0 THEN 'Bounty Awarded'
        ELSE 'No Bounty'
    END AS BountyStatus
FROM 
    TopPosts tp
WHERE 
    tp.ViewCount > 100
UNION ALL
SELECT 
    NULL AS PostId,
    'Summary' AS Title,
    NULL AS CreationDate,
    NULL AS Score,
    NULL AS ViewCount,
    NULL AS RankScore,
    COUNT(*) AS CommentCount,
    SUM(TotalBounty) AS TotalBounty,
    NULL AS TagsList,
    NULL AS FirstClosedDate,
    NULL AS PostStatus,
    NULL AS BountyStatus
FROM 
    TopPosts;
