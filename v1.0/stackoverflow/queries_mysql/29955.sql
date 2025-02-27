
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CommentCount,
        rp.VoteCount
    FROM 
        RankedPosts rp 
    WHERE 
        rp.Rank <= 5  
),
TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(TRIM(BOTH ' ' FROM rp.Tags), '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        FilteredPosts rp
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(TRIM(BOTH ' ' FROM rp.Tags)) - CHAR_LENGTH(REPLACE(TRIM(BOTH ' ' FROM rp.Tags), '><', '')) >= numbers.n - 1
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCounts
    WHERE 
        PostCount > 1  
),
PopularTags AS (
    SELECT 
        Tag
    FROM 
        TopTags
    WHERE 
        TagRank <= 10  
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.CommentCount,
    fp.VoteCount,
    GROUP_CONCAT(pt.Tag SEPARATOR ', ') AS PopularTags
FROM 
    FilteredPosts fp
LEFT JOIN 
    PopularTags pt ON FIND_IN_SET(pt.Tag, TRIM(BOTH ' ' FROM REPLACE(fp.Tags, '><', ',')))
GROUP BY 
    fp.PostId, fp.Title, fp.Body, fp.CommentCount, fp.VoteCount
ORDER BY 
    fp.VoteCount DESC, fp.CommentCount DESC;
