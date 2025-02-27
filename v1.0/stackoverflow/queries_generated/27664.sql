WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        pt.Name AS PostType,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankWithinType
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  -- Filter on upvotes only
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'  -- filter by last year
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, pt.Name, u.DisplayName, u.Reputation
), TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        ViewCount,
        PostType,
        OwnerDisplayName,
        OwnerReputation,
        CommentCount,
        VoteCount,
        RankWithinType
    FROM 
        RankedPosts
    WHERE 
        RankWithinType <= 5  -- Top 5 posts per type
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.ViewCount,
    pp.CommentCount,
    pp.VoteCount,
    pp.OwnerDisplayName,
    pp.OwnerReputation,
    pt.Name AS PostType,
    CONCAT('#', REPLACE(TRIM(BOTH '{}' FROM p.Tags), '><',  ' #')) AS FormattedTags,
    CASE
        WHEN pp.VoteCount > 10 THEN 'Hot'
        WHEN pp.VoteCount BETWEEN 5 AND 10 THEN 'Trending'
        ELSE 'New'
    END AS HotnessStatus
FROM 
    TopPosts pp
JOIN 
    Posts p ON pp.PostId = p.Id
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE 
    pp.OwnerReputation > 100  -- Only include posts from high-reputation users
ORDER BY 
    pp.PostType, pp.VoteCount DESC, pp.ViewCount DESC;
