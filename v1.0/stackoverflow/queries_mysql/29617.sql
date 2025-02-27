
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1          
    LEFT JOIN 
        Comments c ON p.Id = c.PostId                               
    LEFT JOIN 
        Votes v ON p.Id = v.PostId                                  
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id                             
    WHERE 
        p.PostTypeId = 1                                           
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.OwnerUserId, u.DisplayName
),
FilteredPosts AS (
    SELECT
        rp.PostID,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.AnswerCount,
        rp.CommentCount,
        rp.VoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RecentPostRank <= 5                                    
),
PostTags AS (
    SELECT
        p.Id AS PostID,
        GROUP_CONCAT(t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
    FROM
        Posts p
    JOIN
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS tag_name
         FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
               UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7) numbers 
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) as tag_temp
    JOIN
        Tags t ON t.TagName = tag_temp.tag_name
    GROUP BY
        p.Id
)
SELECT 
    fp.PostID,
    fp.Title,
    fp.Body,
    fp.CreationDate,
    fp.OwnerDisplayName,
    fp.AnswerCount,
    fp.CommentCount,
    fp.VoteCount,
    pt.Tags
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostTags pt ON fp.PostID = pt.PostID
ORDER BY 
    fp.CreationDate DESC;
