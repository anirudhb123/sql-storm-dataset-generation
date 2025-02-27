WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerPostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9 -- BountyClose
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- Filter for the last year
    GROUP BY 
        p.Id
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CommentCount,
        rp.TotalBounty
    FROM 
        RankedPosts rp
    WHERE 
        rp.OwnerPostRank = 1 -- Only top posts per user
        AND rp.TotalBounty IS NOT NULL
)
SELECT 
    fp.Title,
    fp.ViewCount,
    fp.CommentCount,
    COALESCE(SUM(b.Class = 1)::int, 0) AS GoldBadgesCount,
    COALESCE(SUM(b.Class = 2)::int, 0) AS SilverBadgesCount,
    COALESCE(SUM(b.Class = 3)::int, 0) AS BronzeBadgesCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    FilteredPosts fp
LEFT JOIN 
    Users u ON fp.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    STRING_TO_ARRAY(substring(p.Tags, 2, length(p.Tags) - 2), ',') t ON p.Id = t.Id -- Simulate split tags
JOIN 
    Posts p ON fp.PostId = p.Id
WHERE 
    t.TagName IS NULL OR t.TagName LIKE 'SQL%' -- Tags should not be null or start with 'SQL'
GROUP BY 
    fp.Title, fp.ViewCount, fp.CommentCount
ORDER BY 
    fp.ViewCount DESC
LIMIT 10;
This query first ranks posts by their score for each user and filters to only retain the top-ranked post per user which has received a bounty. It then aggregates some data about badges and tags while applying various conditions regarding NULL handling and string manipulation. Finally, it outputs the result ordered by view count.
