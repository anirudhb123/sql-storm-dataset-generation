WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes, 
        SUM(v.VoteTypeId = 3) AS DownVotes,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END), 0) AS CloseCount
    FROM Posts p
    LEFT JOIN Posts a ON p.Id = a.ParentId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE p.PostTypeId = 1
    GROUP BY p.Id
),
ActiveTags AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        SUM(1) AS UsageCount
    FROM Tags t
    INNER JOIN Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY t.Id
    HAVING SUM(1) > 100
),
UserPostActivity AS (
    SELECT 
        pu.UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(ps.AnswerCount) AS TotalAnswers
    FROM PostStatistics ps
    JOIN Posts p ON ps.PostId = p.Id
    JOIN Users pu ON p.OwnerUserId = pu.Id 
    GROUP BY pu.UserId
)
SELECT 
    ru.DisplayName,
    ru.Reputation,
    upa.TotalPosts,
    upa.TotalAnswers,
    (upa.TotalPosts - upa.TotalAnswers) AS QuestionsAsked,
    tag.TagName,
    tag.UsageCount
FROM RankedUsers ru
JOIN UserPostActivity upa ON ru.UserId = upa.UserId
JOIN ActiveTags tag ON upa.UserId = ru.UserId
WHERE ru.ReputationRank <= 50
ORDER BY ru.Reputation DESC, tag.UsageCount DESC
LIMIT 10;
