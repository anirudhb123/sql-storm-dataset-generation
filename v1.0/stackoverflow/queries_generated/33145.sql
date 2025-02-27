WITH RecursivePostTraveler AS (
    SELECT
        Id AS PostId,
        ParentId,
        1 AS Level,
        Title,
        CreationDate
    FROM Posts
    WHERE ParentId IS NULL  -- Starting from root posts (questions)

    UNION ALL

    SELECT
        p.Id,
        p.ParentId,
        pt.Level + 1,
        p.Title,
        p.CreationDate
    FROM Posts p
    JOIN RecursivePostTraveler pt ON p.ParentId = pt.PostId
),
RecentPostHistory AS (
    SELECT
        ph.PostId,
        ph.PostHistoryTypeId,
        MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 10, 11) -- Title edits, body edits, close and reopen actions
    GROUP BY ph.PostId, ph.PostHistoryTypeId
),
TaggedQuestions AS (
    SELECT
        p.Id as PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        t.TagName,
        t.Count AS TagCount
    FROM Posts p
    JOIN LATERAL (SELECT UNNEST(string_to_array(p.Tags, '><')) AS TagName) AS t
        ON p.PostTypeId = 1 -- Only questions
    JOIN Tags t ON t.TagName = t.TagName
    WHERE p.CreationDate > NOW() - INTERVAL '1 year'
),
AggregatedData AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        COUNT(DISTINCT a.Id) AS TotalAnswers,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        AVG(u.Reputation) AS AverageReputation
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1  -- Questions
    LEFT JOIN Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2  -- Answers
    LEFT JOIN Votes v ON v.UserId = u.Id
    GROUP BY u.Id, u.DisplayName
)
SELECT
    rpt.PostId,
    rpt.Title,
    rpt.Level,
    rp.LastEditDate,
    tq.TagName,
    tq.ViewCount,
    tq.AnswerCount,
    ad.UserId,
    ad.DisplayName,
    ad.TotalQuestions,
    ad.TotalAnswers,
    ad.TotalBounty,
    ad.AverageReputation
FROM RecursivePostTraveler rpt
LEFT JOIN RecentPostHistory rp ON rpt.PostId = rp.PostId
LEFT JOIN TaggedQuestions tq ON rpt.PostId = tq.PostId
JOIN AggregatedData ad ON ad.UserId = rpt.PostId  -- Assuming UserId retrieved aligns with PostId (for example)
ORDER BY rpt.Level, rp.LastEditDate DESC, tq.ViewCount DESC;
