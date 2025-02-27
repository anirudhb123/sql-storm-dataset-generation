WITH TagAggregates AS (
    SELECT
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(CASE WHEN Posts.ViewCount IS NOT NULL THEN Posts.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN Posts.Score IS NOT NULL THEN Posts.Score ELSE 0 END) AS TotalScore,
        AVG(CASE WHEN Posts.Score IS NOT NULL THEN Posts.Score ELSE NULL END) AS AvgScore
    FROM
        Tags
    JOIN
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '><')::int[])
    GROUP BY
        Tags.TagName
),
TopUsers AS (
    SELECT
        Users.DisplayName,
        SUM(Votes.VoteTypeId = 2) AS TotalUpVotes,
        SUM(Votes.VoteTypeId = 3) AS TotalDownVotes,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN Posts.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS TotalAcceptedAnswers
    FROM
        Users
    LEFT JOIN
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN
        Votes ON Posts.Id = Votes.PostId
    GROUP BY
        Users.DisplayName
    ORDER BY
        TotalUpVotes DESC
    LIMIT 10
),
PostHistorySummary AS (
    SELECT
        PostHistory.PostId,
        COUNT(PostHistory.Id) AS EditCount,
        MAX(PostHistory.CreationDate) AS LastEditDate,
        STRING_AGG(CONCAT(PostHistory.UserDisplayName, ': ', PostHistory.Text), '; ') AS EditComments
    FROM
        PostHistory
    GROUP BY
        PostHistory.PostId
)

SELECT
    t.TagName,
    a.PostCount,
    a.TotalViews,
    a.TotalScore,
    a.AvgScore,
    u.DisplayName AS TopUser,
    u.TotalUpVotes,
    u.TotalDownVotes,
    ph.EditCount,
    ph.LastEditDate,
    ph.EditComments
FROM
    TagAggregates a
JOIN
    Tags t ON a.TagName = t.TagName
LEFT JOIN
    TopUsers u ON TRUE
LEFT JOIN
    PostHistorySummary ph ON (SELECT COUNT(*) FROM Posts p WHERE p.Tags LIKE '%' || t.TagName || '%') > 0
ORDER BY
    a.TotalViews DESC, 
    a.AvgScore DESC;
