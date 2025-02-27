WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankByScore,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.CreationDate DESC) AS RankByDate
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        (SELECT 
            PostId, 
            unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName 
        FROM 
            Posts) AS t ON p.Id = t.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.AnswerCount, pt.Name
),
PopularTags AS (
    SELECT 
        Tags, 
        COUNT(*) AS TagPopularity
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 10
    GROUP BY 
        Tags
    ORDER BY 
        TagPopularity DESC
    LIMIT 5
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.AnswerCount,
    pt.Name AS PostType,
    pt.Id AS PostTypeId,
    pht.Name AS PostHistoryType,
    pht.Id AS PostHistoryTypeId,
    (SELECT STRING_AGG(DISTINCT DISTINCT Tags, ', ') FROM RankedPosts) AS RelatedTags
FROM 
    RankedPosts rp
JOIN 
    PostTypes pt ON rp.PostTypeId = pt.Id
LEFT JOIN 
    PostHistory ph ON ph.PostId = rp.PostId
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE 
    pt.Name LIKE '%Question%' AND 
    rp.Tags IN (SELECT Tags FROM PopularTags)
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;
