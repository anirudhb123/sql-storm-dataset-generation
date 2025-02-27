
WITH PostTags AS (
    SELECT 
        p.Id AS PostId, 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 
         UNION ALL SELECT 10) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1 
),
TagStatistics AS (
    SELECT 
        pt.Tag,
        COUNT(pt.PostId) AS PostCount,
        COUNT(DISTINCT ph.UserId) AS EditorCount, 
        AVG(u.Reputation) AS AvgReputation 
    FROM 
        PostTags pt
    LEFT JOIN 
        PostHistory ph ON ph.PostId = pt.PostId AND ph.PostHistoryTypeId IN (4, 5, 6) 
    LEFT JOIN 
        Users u ON u.Id = ph.UserId
    GROUP BY 
        pt.Tag
),
RankedTags AS (
    SELECT 
        Tag, 
        PostCount, 
        EditorCount, 
        AvgReputation,
        @rank_post_count := IF(@prev_post_count = PostCount, @rank_post_count, @rank_post_count + 1) AS RankByPostCount,
        @prev_post_count := PostCount,
        @rank_editor_count := IF(@prev_editor_count = EditorCount, @rank_editor_count, @rank_editor_count + 1) AS RankByEditorCount,
        @prev_editor_count := EditorCount,
        @rank_avg_reputation := IF(@prev_avg_reputation = AvgReputation, @rank_avg_reputation, @rank_avg_reputation + 1) AS RankByAvgReputation,
        @prev_avg_reputation := AvgReputation
    FROM 
        TagStatistics, 
        (SELECT @rank_post_count := 0, @prev_post_count := NULL, @rank_editor_count := 0, @prev_editor_count := NULL, @rank_avg_reputation := 0, @prev_avg_reputation := NULL) AS r
    ORDER BY 
        PostCount DESC, EditorCount DESC, AvgReputation DESC
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
