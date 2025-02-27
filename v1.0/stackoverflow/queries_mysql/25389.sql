
WITH UserTagCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT t.TagName) AS DistinctTagCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    JOIN (
        SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
        FROM 
            Posts p
        JOIN (
            SELECT 
                1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL 
                SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
        ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    ) t ON TRUE
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        u.Id, u.DisplayName
), 
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        DistinctTagCount,
        TotalViews,
        TotalScore,
        @rownum := @rownum + 1 AS Rank
    FROM 
        UserTagCounts, (SELECT @rownum := 0) r
    ORDER BY 
        TotalViews DESC, TotalScore DESC
),
ActivePostHistories AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.UserId AS EditorId,
        ph.CreationDate AS EditDate,
        ph.Comment,
        ph.Text,
        ph.PostHistoryTypeId
    FROM 
        Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  
)
SELECT 
    ru.DisplayName,
    ru.DistinctTagCount,
    ru.TotalViews,
    ru.TotalScore,
    COUNT(DISTINCT aph.PostId) AS EditedPostCount,
    MAX(aph.EditDate) AS LastEditDate,
    GROUP_CONCAT(DISTINCT aph.Title SEPARATOR ', ') AS EditedPostTitles
FROM 
    RankedUsers ru
LEFT JOIN 
    ActivePostHistories aph ON ru.UserId = aph.EditorId
GROUP BY 
    ru.UserId, ru.DisplayName, ru.DistinctTagCount, ru.TotalViews, ru.TotalScore
HAVING 
    ru.DistinctTagCount > 0
ORDER BY 
    ru.Rank
LIMIT 10;
