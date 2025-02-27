WITH UserVoteStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS Questions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS Answers
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN
        Votes V ON P.Id = V.PostId
    WHERE
        U.Reputation > 0
    GROUP BY
        U.Id, U.DisplayName, U.Reputation
),
PopularTags AS (
    SELECT
        T.TagName,
        COUNT(*) AS TagUsageCount
    FROM
        Tags T
    JOIN
        Posts P ON T.Id = P.Tags::jsonb->>'TagId'::int
    GROUP BY
        T.TagName
    HAVING
        COUNT(*) > 10
),
RecentPostUpdates AS (
    SELECT
        PH.PostId,
        PH.UserId,
        PH.CreationDate,
        PH.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS RowNum
    FROM
        PostHistory PH
    WHERE
        PH.CreationDate >= NOW() - INTERVAL '1 month'
        AND PH.UserId IS NOT NULL
)
SELECT
    U.DisplayName AS User,
    U.Reputation AS UserReputation,
    COALESCE(PU.TagName, 'No Tags') AS Tag,
    UPS.Upvotes AS UserUpvotes,
    UPS.Downvotes AS UserDownvotes,
    UPS.Questions AS UserQuestions,
    UPS.Answers AS UserAnswers,
    COUNT(DISTINCT RPU.PostId) AS RecentPostCount,
    SUM(CASE WHEN RPU.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedPosts,
    SUM(CASE WHEN RPU.PostHistoryTypeId IN (11, 13) THEN 1 ELSE 0 END) AS ReopenedOrRestoredPosts
FROM
    UserVoteStats UPS
LEFT JOIN
    PopularTags PU ON UPS.UserId = (SELECT U2.Id FROM Users U2 WHERE U2.Reputation = (SELECT MAX(Reputation) FROM Users))
LEFT JOIN
    RecentPostUpdates RPU ON UPS.UserId = RPU.UserId
GROUP BY
    U.DisplayName, U.Reputation, PU.TagName
ORDER BY
    UPS.Reputation DESC, RecentPostCount DESC
LIMIT 50;
