WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecencyRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVoteCount
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- UpVotes Only
    WHERE
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND (p.Score >= 0 OR p.ViewCount > 100)
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
        AND ph.CreationDate >= NOW() - INTERVAL '2 years'
),
ExtendedPostInfo AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.RecencyRank,
        rp.CommentCount,
        rp.UpVoteCount,
        cp.CloseReason
    FROM
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    epi.PostId,
    epi.Title,
    epi.CreationDate,
    epi.ViewCount,
    epi.Score,
    COALESCE(epi.CloseReason, 'Open') AS Status,
    CASE 
        WHEN epi.RecencyRank = 1 THEN 'Newest Post by User'
        ELSE 'Other Posts'
    END AS PostCategory,
    (SELECT COUNT(*) FROM Posts WHERE Tags LIKE '%' || SUBSTRING(epi.Title FROM '(\w+)') || '%') AS RelatedTagCount,
    ARRAY_AGG(DISTINCT b.Name) FILTER (WHERE b.UserId IS NOT NULL) AS BadgeNames
FROM 
    ExtendedPostInfo epi
LEFT JOIN 
    Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = epi.PostId)
GROUP BY 
    epi.PostId,
    epi.Title,
    epi.CreationDate,
    epi.ViewCount,
    epi.Score,
    epi.CloseReason,
    epi.RecencyRank
ORDER BY 
    epi.Score DESC,
    epi.ViewCount DESC;
