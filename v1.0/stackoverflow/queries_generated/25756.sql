WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankByTags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  -- Filter for Questions
    GROUP BY 
        p.Id, p.Title, p.Tags, p.Score, u.DisplayName
),
PopularTags AS (
    SELECT 
        t.TagName,
        SUM(rp.Score) AS TotalScore,
        COUNT(rp.PostId) AS QuestionCount
    FROM 
        RankedPosts rp
    CROSS JOIN 
        Tags t ON rp.Tags LIKE '%' || t.TagName || '%'  -- Check if tag is in post's tags
    GROUP BY 
        t.TagName
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Tags,
        rp.Score,
        rp.CommentCount,
        rp.VoteCount,
        pt.TotalScore,
        pt.QuestionCount
    FROM 
        RankedPosts rp
    JOIN 
        PopularTags pt ON rp.Tags LIKE '%' || pt.TagName || '%'  -- Join with popular tags
    WHERE 
        rp.RankByTags <= 5  -- Limit to top 5 posts per tag
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.OwnerDisplayName,
    pp.Tags,
    pp.Score,
    pp.CommentCount,
    pp.VoteCount,
    pp.TotalScore,
    pp.QuestionCount,
    CONCAT('This post has ', pp.CommentCount, ' comments and ', pp.VoteCount, ' votes.') AS EngagementMetrics
FROM 
    PopularPosts pp
ORDER BY 
    pp.TotalScore DESC
LIMIT 10;  -- Top 10 posts with highest total scores
