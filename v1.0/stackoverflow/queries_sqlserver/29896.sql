
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        u.DisplayName AS UserDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts AS p
    LEFT JOIN 
        Users AS u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments AS c ON p.Id = c.PostId
    LEFT JOIN 
        Votes AS v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.Tags, u.DisplayName
),
PopularTags AS (
    SELECT 
        LTRIM(RTRIM(value)) AS Tag
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(Tags, '><')
    WHERE 
        PostTypeId = 1
),
TagFrequency AS (
    SELECT 
        Tag, COUNT(*) AS Frequency
    FROM 
        PopularTags
    GROUP BY 
        Tag
    ORDER BY 
        Frequency DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.Tags,
    rp.UserDisplayName,
    rp.CommentCount,
    rp.VoteCount,
    tf.Tag AS TopTag,
    tf.Frequency AS TagFrequency
FROM 
    RankedPosts AS rp
LEFT JOIN 
    TagFrequency AS tf ON rp.Tags LIKE '%' + tf.Tag + '%' 
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
