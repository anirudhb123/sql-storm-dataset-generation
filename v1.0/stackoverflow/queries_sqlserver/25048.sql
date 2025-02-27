
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= DATEADD(year, -1, '2024-10-01T12:34:56')
),

TagStatistics AS (
    SELECT 
        value AS Tag, 
        COUNT(*) AS PostCount,
        AVG(ViewCount) AS AvgViewCount,
        AVG(Score) AS AvgScore
    FROM 
        RankedPosts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
    GROUP BY 
        value
),

TopTags AS (
    SELECT 
        Tag,
        PostCount,
        AvgViewCount,
        AvgScore,
        RANK() OVER (ORDER BY AvgScore DESC) AS RankScore
    FROM 
        TagStatistics
    WHERE 
        PostCount > 10 
),

PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        tt.Tag,
        tt.RankScore
    FROM 
        RankedPosts rp
    JOIN 
        TopTags tt ON tt.Tag IN (SELECT value FROM STRING_SPLIT(SUBSTRING(rp.Tags, 2, LEN(rp.Tags) - 2), '><'))
    WHERE 
        rp.TagRank <= 3 
)

SELECT 
    pp.PostId,
    pp.Title,
    pp.ViewCount,
    pp.Score,
    pp.Tag,
    pp.RankScore,
    COUNT(c.Id) AS CommentCount,
    AVG(v.BountyAmount) AS AvgBounty 
FROM 
    PopularPosts pp
LEFT JOIN 
    Comments c ON pp.PostId = c.PostId
LEFT JOIN 
    Votes v ON pp.PostId = v.PostId AND v.VoteTypeId = 8 
GROUP BY 
    pp.PostId, pp.Title, pp.ViewCount, pp.Score, pp.Tag, pp.RankScore
ORDER BY 
    pp.RankScore, pp.Score DESC;
