
WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' 
        AND p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, u.DisplayName
),
TagStats AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', n.n), ',', -1) AS Tag
    FROM 
        FilteredPosts fp
    JOIN 
        (SELECT a.N + 1 as n FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a) n
    ON CHAR_LENGTH(fp.Tags) - CHAR_LENGTH(REPLACE(fp.Tags, ',', '')) >= n.n - 1
),
TagAggregate AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        TagStats
    GROUP BY 
        Tag
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Author,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes,
    GROUP_CONCAT(DISTINCT ta.Tag ORDER BY ta.Tag SEPARATOR ', ') AS Tags,
    COUNT(ta.Tag) AS UniqueTagCount
FROM 
    FilteredPosts fp
LEFT JOIN 
    TagAggregate ta ON FIND_IN_SET(ta.Tag, fp.Tags)
GROUP BY 
    fp.PostId, fp.Title, fp.CreationDate, fp.Author, fp.CommentCount, fp.UpVotes, fp.DownVotes
ORDER BY 
    fp.UpVotes DESC,
    fp.CommentCount DESC,
    fp.CreationDate DESC;
