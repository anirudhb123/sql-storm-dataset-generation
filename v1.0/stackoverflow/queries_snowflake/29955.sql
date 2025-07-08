
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
        TRIM(BOTH ' ' FROM t) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        FilteredPosts rp,
        LATERAL FLATTEN(input => SPLIT(TRIM(BOTH ' ' FROM rp.Tags), '><')) AS t
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
    LISTAGG(pt.Tag, ', ') AS PopularTags
FROM 
    FilteredPosts fp
LEFT JOIN 
    PopularTags pt ON pt.Tag IN (SELECT TRIM(BOTH ' ' FROM t) FROM LATERAL FLATTEN(input => SPLIT(TRIM(BOTH ' ' FROM fp.Tags), '><')) AS t)
GROUP BY 
    fp.PostId, fp.Title, fp.Body, fp.CommentCount, fp.VoteCount
ORDER BY 
    fp.VoteCount DESC, fp.CommentCount DESC;
