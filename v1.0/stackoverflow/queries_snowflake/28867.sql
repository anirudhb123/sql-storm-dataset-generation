
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
        TRIM(value) AS Tag
    FROM 
        FilteredPosts,
        LATERAL FLATTEN(INPUT => SPLIT(Tags, ','))
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
    LISTAGG(DISTINCT ta.Tag, ', ') AS Tags,
    COUNT(DISTINCT ta.Tag) AS UniqueTagCount
FROM 
    FilteredPosts fp
LEFT JOIN 
    TagAggregate ta ON ta.Tag IN (SELECT TRIM(value) FROM LATERAL FLATTEN(INPUT => SPLIT(fp.Tags, ',')))
GROUP BY 
    fp.PostId, fp.Title, fp.CreationDate, fp.Author, fp.CommentCount, fp.UpVotes, fp.DownVotes
ORDER BY 
    fp.UpVotes DESC,
    fp.CommentCount DESC,
    fp.CreationDate DESC;
