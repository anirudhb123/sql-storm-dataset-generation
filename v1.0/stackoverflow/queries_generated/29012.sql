WITH TagStatistics AS (
    SELECT
        tags.TagName,
        COUNT(posts.Id) AS PostCount,
        SUM(
            CASE
                WHEN posts.Score > 0 THEN 1
                ELSE 0
            END
        ) AS PositiveScoreCount,
        SUM(posts.ViewCount) AS TotalViewCount
    FROM Tags AS tags
    LEFT JOIN Posts AS posts ON tags.Id = ANY(string_to_array(substring(posts.Tags, 2, length(posts.Tags)-2), '><')::int[])
    GROUP BY tags.TagName
),
TopTags AS (
    SELECT
        TagName,
        PostCount,
        PositiveScoreCount,
        TotalViewCount,
        RANK() OVER (ORDER BY TotalViewCount DESC) AS ViewCountRank,
        RANK() OVER (ORDER BY PostCount DESC) AS PostCountRank
    FROM TagStatistics
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionCount,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users AS u
    LEFT JOIN Posts AS p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN Posts AS a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2
    LEFT JOIN Badges AS b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostHistoryAnalysis AS (
    SELECT
        ph.UserId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory AS ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 24) -- Edit Title, Edit Body, Suggested Edit Applied
    GROUP BY ph.UserId
),
FinalReport AS (
    SELECT
        ua.UserId,
        ua.DisplayName,
        ua.QuestionCount,
        ua.AnswerCount,
        ua.GoldBadges,
        ua.SilverBadges,
        ua.BronzeBadges,
        IFNULL(pa.EditCount, 0) AS EditCount,
        IFNULL(pa.LastEditDate, 'N/A') AS LastEditDate,
        tt.TagName,
        tt.PostCount,
        tt.PositiveScoreCount
    FROM UserActivity AS ua
    LEFT JOIN PostHistoryAnalysis AS pa ON ua.UserId = pa.UserId
    LEFT JOIN TopTags AS tt ON tt.ViewCountRank <= 10 -- Limiting to top 10 tags by view count
)
SELECT
    *
FROM FinalReport
ORDER BY QuestionCount DESC, AnswerCount DESC;
