
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
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR 
),

TagStatistics AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS Tag, 
        COUNT(*) AS PostCount,
        AVG(ViewCount) AS AvgViewCount,
        AVG(Score) AS AvgScore
    FROM 
        RankedPosts
    JOIN 
        (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n
    ON LENGTH(Tags) - LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    GROUP BY 
        Tag
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
        TopTags tt ON FIND_IN_SET(tt.Tag, SUBSTRING(rp.Tags, 2, LENGTH(rp.Tags) - 2)) > 0
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
