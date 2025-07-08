
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes 
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '7 days'
        AND p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName
),
TopTags AS (
    SELECT 
        VALUE AS Tag
    FROM 
        RecentPosts, 
        TABLE(FLATTEN(INPUT => SPLIT(Tags, '><')))
),
TagStatistics AS (
    SELECT 
        Tag,
        COUNT(Tag) AS UsageCount
    FROM 
        TopTags
    GROUP BY 
        Tag
    ORDER BY 
        UsageCount DESC
    LIMIT 5
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerName,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    LISTAGG(tt.Tag, ', ') AS TopTags
FROM 
    RecentPosts rp
JOIN 
    TagStatistics tt ON tt.Tag IN (SELECT VALUE FROM TABLE(FLATTEN(INPUT => SPLIT(rp.Tags, '><'))))
GROUP BY 
    rp.PostId, rp.Title, rp.OwnerName, rp.CommentCount, rp.UpVotes, rp.DownVotes
ORDER BY 
    rp.CommentCount DESC, rp.UpVotes DESC;
