
WITH UserPostAnalytics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        MAX(u.Reputation) AS MaxReputation,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS PopularTags
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        (SELECT DISTINCT TagName FROM 
            (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1)) AS TagName
            FROM 
                (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
                 UNION ALL SELECT 9 UNION ALL SELECT 10) AS n
            JOIN Posts p ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1) AS tags) AS t
        ON TRUE
    WHERE 
        u.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        COUNT(ph.Id) AS EditCount,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN 1 ELSE 0 END) AS ContentEditCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title
),
FinalResults AS (
    SELECT 
        up.DisplayName,
        up.PostCount,
        up.BadgeCount,
        up.QuestionCount,
        up.AnswerCount,
        up.PositivePosts,
        up.NegativePosts,
        up.MaxReputation,
        ph.Title,
        ph.EditCount,
        ph.ContentEditCount,
        ph.CloseCount,
        @rank := @rank + 1 AS Ranking
    FROM 
        UserPostAnalytics up
    JOIN 
        PostHistoryStats ph ON up.UserId = ph.PostId,
        (SELECT @rank := 0) r
    ORDER BY 
        up.MaxReputation DESC
)

SELECT 
    Ranking,
    DisplayName,
    PostCount,
    BadgeCount,
    QuestionCount,
    AnswerCount,
    PositivePosts,
    NegativePosts,
    MaxReputation,
    Title,
    EditCount,
    ContentEditCount,
    CloseCount
FROM 
    FinalResults
ORDER BY 
    Ranking, MaxReputation DESC;
