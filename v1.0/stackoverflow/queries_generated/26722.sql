WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY u.Reputation ORDER BY p.Score DESC) as RankByScore,
        ROW_NUMBER() OVER (PARTITION BY u.Reputation ORDER BY p.ViewCount DESC) as RankByViews
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
FilteredPosts AS (
    SELECT 
        PostId, 
        Title,
        Tags,
        CreationDate,
        Score,
        ViewCount,
        CommentCount,
        RankByScore,
        RankByViews
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 5 OR RankByViews <= 5
),
TagStats AS (
    SELECT 
        TRIM(UNNEST(string_to_array(Tags, '>')) ) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        FilteredPosts
    GROUP BY 
        Tag
)
SELECT 
    t.Tag, 
    ts.PostCount,
    t.TagName,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId IN (SELECT PostId FROM FilteredPosts)) AS TotalVotes,
    SUM(f.ViewCount) AS TotalViews
FROM 
    TagStats ts
JOIN 
    Tags t ON ts.Tag = t.TagName
JOIN 
    FilteredPosts f ON f.Tags LIKE '%' || t.TagName || '%'
GROUP BY 
    t.Tag, ts.PostCount, t.TagName
ORDER BY 
    TotalVotes DESC, TotalViews DESC;
