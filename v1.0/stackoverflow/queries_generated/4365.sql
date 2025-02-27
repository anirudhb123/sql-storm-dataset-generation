WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.OwnerUserId) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
),
TopPostDetails AS (
    SELECT 
        rp.Id,
        rp.Title,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.rn = 1
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts pt ON pt.Tags LIKE '%' + t.TagName + '%'
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 5
)
SELECT 
    t.TagName,
    p.Title AS TopPostTitle,
    p.OwnerDisplayName,
    p.Score,
    p.ViewCount
FROM 
    TopPostDetails p
JOIN 
    PostLinks pl ON pl.PostId = p.Id
JOIN 
    TopTags t ON pl.RelatedPostId IN (SELECT Id FROM Posts WHERE Tags LIKE '%' + t.TagName + '%')
LEFT JOIN 
    Votes v ON v.PostId = p.Id
WHERE 
    v.VoteTypeId IN (2, 3)  -- UpVotes or DownVotes
GROUP BY 
    t.TagName, p.Title, p.OwnerDisplayName, p.Score, p.ViewCount
HAVING 
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) > 
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END)  -- More upvotes than downvotes
ORDER BY 
    t.TagName;
