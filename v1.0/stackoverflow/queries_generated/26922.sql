WITH PostTags AS (
    SELECT 
        p.Id AS PostId, 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
TagStatistics AS (
    SELECT 
        Tag,
        COUNT(PostId) AS PostCount,
        COUNT(DISTINCT ph.UserId) AS EditorCount, -- Count distinct editors for the tags
        AVG(u.Reputation) AS AvgReputation -- Average reputation of users who edited posts
    FROM 
        PostTags pt
    LEFT JOIN 
        PostHistory ph ON ph.PostId = pt.PostId AND ph.PostHistoryTypeId IN (4, 5, 6) -- Edits on titles, bodies, and tags
    LEFT JOIN 
        Users u ON u.Id = ph.UserId
    GROUP BY 
        Tag
),
RankedTags AS (
    SELECT 
        Tag, 
        PostCount, 
        EditorCount, 
        AvgReputation,
        RANK() OVER (ORDER BY PostCount DESC) AS RankByPostCount,
        RANK() OVER (ORDER BY EditorCount DESC) AS RankByEditorCount,
        RANK() OVER (ORDER BY AvgReputation DESC) AS RankByAvgReputation
    FROM 
        TagStatistics
)
SELECT 
    rt.Tag,
    rt.PostCount,
    rt.EditorCount,
    rt.AvgReputation,
    CASE 
        WHEN rt.RankByPostCount <= 5 THEN 'Top 5 by Posts'
        WHEN rt.RankByEditorCount <= 5 THEN 'Top 5 by Editors'
        WHEN rt.RankByAvgReputation <= 5 THEN 'Top 5 by Reputation'
        ELSE 'Other'
    END AS Category
FROM 
    RankedTags rt
ORDER BY 
    rt.RankByPostCount, rt.RankByEditorCount, rt.RankByAvgReputation;
