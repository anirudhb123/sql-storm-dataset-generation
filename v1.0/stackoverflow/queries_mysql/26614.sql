
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName, p.PostTypeId
),

AggregatedByTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    JOIN 
        (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION 
         SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        Tag
),

PostWithTopTags AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Author,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        a.Tag
    FROM 
        RankedPosts rp
    JOIN 
        AggregatedByTags a ON rp.Title LIKE CONCAT('%', a.Tag, '%')
    WHERE 
        rp.Rank <= 10 
)

SELECT 
    p.PostId,
    p.Title,
    p.Author,
    p.CommentCount,
    p.UpVotes,
    p.DownVotes,
    GROUP_CONCAT(p.Tag SEPARATOR ', ') AS Tags
FROM 
    PostWithTopTags p
GROUP BY 
    p.PostId, p.Title, p.Author, p.CommentCount, p.UpVotes, p.DownVotes
ORDER BY 
    p.UpVotes DESC, p.CommentCount DESC;
