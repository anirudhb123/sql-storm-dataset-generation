
WITH UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        UpVotes,
        DownVotes,
        @rank := IF(@prev_reputation = Reputation, @rank, @rank + 1) AS ReputationRank,
        @prev_reputation := Reputation
    FROM
        UserStats,
        (SELECT @rank := 0, @prev_reputation := NULL) r
    ORDER BY
        Reputation DESC
),
ActiveTags AS (
    SELECT
        t.Id AS TagId,
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews
    FROM
        Tags t
    JOIN Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    WHERE
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY
        t.Id, t.TagName
),
MostPopularTags AS (
    SELECT
        TagId,
        TagName,
        PostCount,
        TotalViews,
        @view_rank := IF(@prev_views = TotalViews, @view_rank, @view_rank + 1) AS ViewRank,
        @prev_views := TotalViews
    FROM
        ActiveTags,
        (SELECT @view_rank := 0, @prev_views := NULL) r
    ORDER BY
        TotalViews DESC
)
SELECT
    u.DisplayName AS UserName,
    u.Reputation,
    t.TagName,
    t.TotalViews,
    t.PostCount,
    u.QuestionCount,
    u.UpVotes,
    u.DownVotes
FROM
    TopUsers u
JOIN
    MostPopularTags t ON u.PostCount > 0
WHERE
    u.ReputationRank <= 10 AND t.ViewRank <= 5
ORDER BY
    u.Reputation DESC,
    t.TotalViews DESC;
