WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END), 0) AS CloseReopenedCount,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed,
        MIN(p.CreationDate) AS FirstPostDate,
        MAX(p.CreationDate) AS LastPostDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN LATERAL (
        SELECT *,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY ph.CreationDate DESC) AS rn
        FROM VoteTypes vt
        WHERE vt.Id IN (2, 3) AND vt.Id IS NOT NULL
    ) AS votetype ON votetype.PostId = p.Id
    LEFT JOIN LATERAL (
        SELECT UNNEST(string_to_array(p.Tags, '>')) AS TagName
    ) AS t ON true
    GROUP BY u.Id, u.DisplayName
),
RankedUserActivity AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY Reputation DESC) AS ReputationCategory
    FROM (
        SELECT 
            UserId,
            DisplayName,
            QuestionCount,
            AnswerCount,
            CloseReopenedCount,
            TotalPosts,
            UserRank,
            TagsUsed,
            FirstPostDate,
            LastPostDate
        FROM UserActivity
    ) AS ua
)
SELECT *
FROM RankedUserActivity r
WHERE 
    (TotalPosts > 10 OR (QuestionCount + AnswerCount) > 15) 
    AND (TagsUsed IS NOT NULL AND TagsUsed LIKE '%SQL%')
    AND (FirstPostDate IS NOT NULL OR LastPostDate IS NULL OR LastPostDate > NOW() - INTERVAL '1 year')
ORDER BY UserRank DESC, LastPostDate DESC
LIMIT 100;

This query applies several SQL constructs, including Common Table Expressions (CTEs), window functions, lateral joins, string aggregation, and complex filtering logic. It retrieves user activity metrics, counts their posts, and categorizes users based on their reputation while applying specific conditions to filter results, ensuring it's practical while exploring obscure SQL semantics.
