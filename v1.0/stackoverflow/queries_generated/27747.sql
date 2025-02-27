WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER(PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
),
TagStatistics AS (
    SELECT 
        pg.PostId,
        STRING_AGG(t.TagName, ', ') AS Tags,
        COUNT(DISTINCT p.Id) AS RelatedPostsCount
    FROM 
        PostLinks pg
    JOIN 
        Posts p ON pg.RelatedPostId = p.Id
    JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag_name ON true
    JOIN 
        Tags t ON t.TagName = tag_name
    GROUP BY 
        pg.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    ts.Tags,
    ts.RelatedPostsCount
FROM 
    RankedPosts rp
LEFT JOIN 
    TagStatistics ts ON rp.PostId = ts.PostId
ORDER BY 
    rp.UpVotes DESC, rp.CreationDate DESC
LIMIT 10;
