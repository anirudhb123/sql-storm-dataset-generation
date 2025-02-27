WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(AVG(p.Score), 0) AS AvgPostScore,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT t.Id) AS TagCount,
        STRING_AGG(t.TagName, ', ') AS TagsList
    FROM 
        Posts p
    LEFT JOIN 
        STRING_TO_ARRAY(CASE WHEN p.Tags IS NULL THEN '' ELSE SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2) END, '>') AS tag_names
    ON tag_names IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = TRIM(tag_names)
    GROUP BY 
        p.Id
),
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount,
        STRING_AGG(DISTINCT CONCAT(u.DisplayName, ' (', TO_CHAR(ph.CreationDate, 'YYYY-MM-DD HH24:MI:SS'), ')'), '; ') AS UserHistories
    FROM 
        PostHistory ph
    LEFT JOIN 
        Users u ON ph.UserId = u.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13, 14) 
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
FinalAnalysis AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        ua.TotalPosts,
        ua.TotalQuestions,
        ua.TotalAnswers,
        ua.AvgPostScore,
        pt.TagCount,
        pt.TagsList,
        ph.LastPostDate,
        COALESCE(pha.HistoryCount, 0) AS TotalHistoryEntries,
        COALESCE(pha.UserHistories, 'No History') AS LastModifiedBy
    FROM 
        UserActivity ua
    LEFT JOIN 
        PostTags pt ON pt.PostId IN (SELECT PostId FROM Posts WHERE OwnerUserId = ua.UserId)
    LEFT JOIN 
        (SELECT 
            ph.PostId,
            COUNT(*) AS HistoryCount 
         FROM 
            PostHistory ph 
         WHERE 
            ph.PostHistoryTypeId IN (10, 11, 12, 13, 14)
         GROUP BY 
            ph.PostId) AS pha ON pha.PostId = pt.PostId
    ORDER BY 
        ua.Reputation DESC
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    AvgPostScore,
    TagCount,
    TagsList,
    LastPostDate,
    TotalHistoryEntries,
    LastModifiedBy
FROM 
    FinalAnalysis
WHERE 
    Reputation > (SELECT AVG(Reputation) FROM Users) 
ORDER BY 
    TotalPosts DESC, AvgPostScore DESC 
LIMIT 100;
