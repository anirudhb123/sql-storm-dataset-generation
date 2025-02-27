WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.Reputation AS OwnerReputation,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.Reputation, p.ViewCount
),
HighScoringPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        OwnerReputation,
        ViewCount,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        Score > (SELECT AVG(Score) FROM Posts)
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 5
)
SELECT 
    hsp.PostId,
    hsp.Title,
    hsp.CreationDate,
    hsp.Score,
    hsp.OwnerReputation,
    hsp.ViewCount,
    hsp.CommentCount,
    pt.TagName,
    pt.PostCount
FROM 
    HighScoringPosts hsp
JOIN 
    PostLinks pl ON hsp.PostId = pl.PostId
JOIN 
    PopularTags pt ON pl.RelatedPostId = pt.PostCount
WHERE 
    hsp.ViewCount > 100
ORDER BY 
    hsp.Score DESC, hsp.ViewCount DESC;
