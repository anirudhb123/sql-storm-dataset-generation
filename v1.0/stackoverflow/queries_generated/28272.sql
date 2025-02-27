WITH TagStatistics AS (
    SELECT
        t.Id AS TagId,
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(p.Score) AS AvgScore,
        MAX(p.CreationDate) AS LatestPostDate
    FROM
        Tags t
    LEFT JOIN
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    GROUP BY
        t.Id, t.TagName
),
UserContribution AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(v.BountyAmount) AS TotalBounties
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    GROUP BY
        u.Id, u.DisplayName
),
PostHistorySummary AS (
    SELECT
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 24 THEN 1 END) AS EditCount
    FROM
        PostHistory ph
    GROUP BY
        ph.PostId
)

SELECT
    ts.TagId,
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.AvgScore,
    ts.LatestPostDate,
    uc.UserId,
    uc.DisplayName,
    uc.TotalPosts,
    uc.TotalQuestions,
    uc.TotalAnswers,
    uc.TotalBounties,
    phs.CloseReopenCount,
    phs.DeleteCount,
    phs.EditCount
FROM
    TagStatistics ts
JOIN
    UserContribution uc ON ts.PostCount > 0
JOIN
    PostHistorySummary phs ON phs.CloseReopenCount > 0
ORDER BY
    ts.AvgScore DESC, uc.TotalPosts DESC, ts.LatestPostDate DESC;
