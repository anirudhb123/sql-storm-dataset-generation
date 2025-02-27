
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.PostTypeId, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        Author,
        CommentCount,
        VoteCount
    FROM 
        RankedPosts 
    WHERE 
        Rank <= 10
)
SELECT 
    fp.Title,
    fp.Author,
    fp.CommentCount,
    fp.VoteCount,
    GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS TagList
FROM 
    FilteredPosts fp
LEFT JOIN 
    Posts p ON fp.PostId = p.Id
LEFT JOIN 
    (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) tag 
     FROM Posts p
     JOIN (SELECT 1 as n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1) AS tag ON TRUE
LEFT JOIN 
    Tags t ON tag.tag = t.TagName
GROUP BY 
    fp.Title, fp.Author, fp.CommentCount, fp.VoteCount
ORDER BY 
    fp.VoteCount DESC;
