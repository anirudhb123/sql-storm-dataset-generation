
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.Score,
        COALESCE(NULLIF(p.Tags, ''), '@EMPTY') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
PostTags AS (
    SELECT 
        p.PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '> <', numbers.n), '> <', -1) AS Tag
    FROM 
        RankedPosts p
    JOIN 
        (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
         UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers ON CHAR_LENGTH(p.Tags)
        -CHAR_LENGTH(REPLACE(p.Tags, '> <', '')) >= numbers.n - 1
),
TagCounts AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        PostTags
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS TopRank
    FROM 
        TagCounts
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Owner,
    rp.CreationDate,
    rp.Score,
    rp.Tags,
    tt.Tag AS MostUsedTag,
    tt.TagCount AS MostUsedTagCount,
    CASE 
        WHEN rp.PostTypeId = 1 THEN 'Question'
        ELSE 'Other'
    END AS PostType,
    (SELECT 
        COUNT(*) 
     FROM 
        Votes v 
     WHERE 
        v.PostId = rp.PostId 
        AND v.VoteTypeId = 3) AS DownVotes,
    (SELECT 
        COUNT(*) 
     FROM 
        Votes v 
     WHERE 
        v.PostId = rp.PostId 
        AND v.VoteTypeId = 2) AS UpVotes
FROM 
    RankedPosts rp
LEFT JOIN 
    TopTags tt ON tt.TopRank = 1
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC,
    rp.CreationDate DESC
LIMIT 10;
