WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.DisplayName AS Author,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ARRAY_LENGTH(string_to_array(p.Tags, '><'), 1) AS TagCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 YEAR'
),
TopPostsByType AS (
    SELECT 
        postTypeId,
        array_agg(PostId) AS TopPostIds
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
    GROUP BY 
        PostTypeId
),
PostScoreSummaries AS (
    SELECT 
        p.PostTypeId,
        COUNT(*) AS PostCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AverageViewCount,
        MAX(p.Score) AS MaxScore,
        MIN(p.Score) AS MinScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 YEAR'
    GROUP BY 
        p.PostTypeId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        p.Title AS PostTitle,
        ph.CreationDate AS HistoryDate,
        ph.UserDisplayName,
        ph.Comment,
        ph.Text
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '1 MONTH'
        AND ph.PostHistoryTypeId IN (10, 11, 12) -- Close, Reopen, Delete events
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(tp.TopPostIds) AS PostCount
    FROM 
        Tags t
    JOIN 
        TopPostsByType tp ON tp.TopPostIds::int[] && ARRAY(SELECT p.Id FROM Posts p WHERE p.Tags LIKE '%' || t.TagName || '%')
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
)
SELECT 
    r.PostId,
    r.Title,
    r.Author,
    r.CreationDate,
    r.ViewCount,
    r.Score,
    r.TagCount,
    s.PostCount,
    s.TotalScore,
    s.AverageViewCount,
    s.MaxScore,
    s.MinScore,
    h.HistoryDate,
    h.UserDisplayName AS Editor,
    h.Comment AS EditorComment,
    h.Text AS EditContent,
    tt.TagName,
    tt.PostCount AS TagPostCount
FROM 
    RankedPosts r
LEFT JOIN 
    PostScoreSummaries s ON r.PostTypeId = s.PostTypeId
LEFT JOIN 
    PostHistoryDetails h ON r.PostId = h.PostId
LEFT JOIN 
    TopTags tt ON r.Tags LIKE '%' || tt.TagName || '%'
WHERE 
    r.Rank <= 5
ORDER BY 
    r.Score DESC, 
    r.ViewCount DESC;
