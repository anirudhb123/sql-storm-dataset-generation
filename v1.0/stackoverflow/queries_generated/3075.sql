WITH UserReputation AS (
    SELECT 
        Id,
        Reputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
),
PopularTags AS (
    SELECT 
        TagName,
        COUNT(*) AS UsageCount
    FROM Posts
    CROSS JOIN LATERAL string_to_array(Tags, ',') AS TagArray(Tag)
    GROUP BY TagName
    HAVING COUNT(*) > 10
),
QuestionWithAcceptedAnswers AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.AcceptedAnswerId,
        COALESCE(a.Score, 0) AS AcceptedScore,
        p.CreationDate,
        p.OwnerUserId
    FROM Posts p
    LEFT JOIN Posts a ON p.AcceptedAnswerId = a.Id
    WHERE p.PostTypeId = 1
),
ClosedQuestions AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId
)
SELECT 
    u.DisplayName AS UserName,
    ur.Reputation,
    qt.QuestionId,
    qt.Title,
    qt.AcceptedScore,
    qt.CreationDate,
    COALESCE(cq.LastClosedDate, 'No closure') AS LastClosedDate,
    pt.TagName,
    pt.UsageCount
FROM UserReputation ur
JOIN Users u ON u.Id = ur.Id
JOIN QuestionWithAcceptedAnswers qt ON qt.OwnerUserId = u.Id
LEFT JOIN ClosedQuestions cq ON cq.PostId = qt.QuestionId
JOIN PopularTags pt ON pt.TagName LIKE '%SQL%'
WHERE ur.Reputation > 100
ORDER BY ur.Reputation DESC, qt.AcceptedScore DESC;
