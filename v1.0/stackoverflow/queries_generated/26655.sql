WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ARRAY_AGG(DISTINCT t.TagName) AS TagList,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankByScore,
        RANK() OVER (PARTITION BY pt.Name ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month' 
    GROUP BY 
        p.Id, pt.Name
),
TopRankedPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.RankByScore <= 10 THEN 'Top Score'
            WHEN rp.RankByViews <= 10 THEN 'Top Views'
            ELSE 'Regular'
        END AS Classification
    FROM 
        RankedPosts rp
)
SELECT 
    trp.PostId,
    trp.Title,
    trp.CreationDate,
    trp.ViewCount,
    trp.Score,
    trp.TagList,
    trp.CommentCount,
    trp.Classification
FROM 
    TopRankedPosts trp
WHERE 
    trp.Classification IN ('Top Score', 'Top Views')
ORDER BY 
    trp.Classification, trp.Score DESC, trp.ViewCount DESC;
