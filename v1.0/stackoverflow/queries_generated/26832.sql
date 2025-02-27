WITH PostTagCounts AS (
    SELECT
        p.Id AS PostId,
        COUNT(DISTINCT pt.TagName) AS TagCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM
        Posts p
    LEFT JOIN
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS pt(TagName) ON TRUE
    GROUP BY
        p.Id
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        AVG(UPPER(SUBSTRING(p.Body FROM 1 FOR 100))) AS AvgBodySample
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id
),
PostHistoryMeta AS (
    SELECT
        ph.PostId,
        MAX(ph.CreationDate) AS LastEdited,
        COUNT(DISTINCT ph.UserId) AS EditCount,
        STRING_AGG(DISTINCT CONCAT(ph.UserDisplayName, ': ', ph.Comment), '; ') AS EditComments
    FROM
        PostHistory ph
    GROUP BY
        ph.PostId
),
FinalBenchmark AS (
    SELECT
        u.DisplayName AS UserName,
        u.Reputation,
        u.Location,
        u.CreationDate AS UserCreationDate,
        p.Title,
        p.Body,
        p.ViewCount,
        pfc.TagCount,
        uac.TotalPosts,
        uac.TotalQuestions,
        uac.TotalAnswers,
        phm.LastEdited,
        phm.EditCount,
        phm.EditComments
    FROM
        Users u
    JOIN
        UserActivity uac ON u.Id = uac.UserId
    JOIN
        Posts p ON u.Id = p.OwnerUserId
    JOIN
        PostTagCounts pfc ON pfc.PostId = p.Id
    LEFT JOIN
        PostHistoryMeta phm ON phm.PostId = p.Id
    WHERE
        u.Reputation > 1000 AND
        p.ViewCount > 10
)
SELECT
    *
FROM
    FinalBenchmark
ORDER BY
    u.Reputation DESC, 
    p.ViewCount DESC
LIMIT 100;
