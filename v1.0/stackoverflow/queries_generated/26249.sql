WITH TagCounts AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%<'+t.TagName+'>%'
    GROUP BY 
        t.TagName
),
PopularPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.ViewCount, 
        p.Score,
        p.CreationDate, 
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        TagCounts tc ON p.Tags LIKE '%<' || tc.TagName || '>%' 
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
    GROUP BY 
        p.Id 
    HAVING 
        COUNT(t.TagName) >= 3  -- At least 3 tags
    ORDER BY 
        p.Score DESC, p.ViewCount DESC
    LIMIT 
        10
),
VotesInfo AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.Id IN (SELECT Id FROM PopularPosts)
    GROUP BY 
        p.Id
)
SELECT 
    pp.Title,
    pp.ViewCount,
    pp.Score,
    vt.TotalVotes,
    vt.Upvotes,
    vt.Downvotes,
    (SELECT COUNT(c.Id) FROM Comments c WHERE c.PostId = pp.Id) AS CommentCount,
    (SELECT COUNT(b.Id) FROM Badges b WHERE b.UserId = pp.OwnerUserId) AS BadgeCount,
    pp.Tags
FROM 
    PopularPosts pp
JOIN 
    VotesInfo vt ON pp.Id = vt.PostId
ORDER BY 
    pp.Score DESC, pp.ViewCount DESC;
