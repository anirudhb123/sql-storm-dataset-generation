WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ARRAY_AGG(DISTINCT t.TagName) AS TagList,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM p.CreationDate) ORDER BY p.Score DESC) AS YearRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[])
    WHERE 
        p.PostTypeId = 1  -- Filter for Questions
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, p.ViewCount, p.Score
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[])
    WHERE 
        p.PostTypeId = 1  -- Filter for Questions
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(pt.PostId) > 10  -- Filter tags with more than 10 questions
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10  -- Closed posts only
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    rp.TagList,
    pt.PostCount AS PopularTagCount,
    (SELECT COUNT(*) FROM ClosedPosts cp WHERE cp.PostId = rp.PostId) AS IsClosed
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags pt ON pt.TagName = ANY(rp.TagList)
WHERE 
    YearRank <= 5 -- Top 5 posts per year based on score
ORDER BY 
    rp.CreationDate DESC;
