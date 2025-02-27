WITH TagPosts AS (
    SELECT 
        p.Id AS PostId,
        t.TagName,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY t.TagName ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.Score > 0 -- Only questions with positive scores
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        pt.Name AS PostHistoryType,
        ph.CreationDate AS HistoryDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RecentRank
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13) -- Close, Reopen, Delete, Undelete
),
HighScoredUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(p.Score) > 100 -- Only users with total question score above 100
),
PopularTags AS (
    SELECT 
        TagName, 
        COUNT(PostId) AS PostCount
    FROM 
        TagPosts
    WHERE 
        Rank <= 5 -- Top 5 questions per tag
    GROUP BY 
        TagName
    ORDER BY 
        PostCount DESC
),
TagHistoryAnalysis AS (
    SELECT 
        tg.TagName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT ph.Id) AS HistoryCount,
        AVG(EXTRACT(EPOCH FROM (rh.HistoryDate - tg.CreationDate)) / 86400) AS AvgDaysFromCreationToHistory
    FROM 
        Tags tg
    LEFT JOIN 
        TagPosts p ON tg.TagName = p.TagName
    LEFT JOIN 
        RecentPostHistory ph ON p.PostId = ph.PostId
    GROUP BY 
        tg.TagName
)
SELECT 
    th.TagName,
    th.TotalPosts,
    th.HistoryCount,
    th.AvgDaysFromCreationToHistory,
    u.DisplayName AS HighScoredUser,
    u.TotalScore
FROM 
    TagHistoryAnalysis th
LEFT JOIN 
    HighScoredUsers u ON th.TotalPosts > 10 -- Users with more than 10 posts associated with tags
WHERE 
    th.HistoryCount > 5 -- Only tags with more than 5 historical changes
ORDER BY 
    th.TotalPosts DESC, 
    u.TotalScore DESC;
