
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        (SELECT COUNT(v.Id) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(v.Id) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(MONTH, -6, GETDATE())  
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, u.DisplayName
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        (SELECT value AS tag FROM STRING_SPLIT(p.Tags, '>')) AS tag ON 1 = 1
    JOIN 
        Tags t ON t.TagName = tag.tag
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    rp.Owner,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    pt.Tags
FROM 
    RecentPosts rp
JOIN 
    PostTags pt ON rp.PostId = pt.PostId
ORDER BY 
    rp.ViewCount DESC, rp.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
