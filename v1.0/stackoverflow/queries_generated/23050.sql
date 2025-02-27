WITH TagUsage AS (
    SELECT
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM
        Tags T
    LEFT JOIN
        Posts P ON T.Id = ANY(string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><')::int[])
    GROUP BY
        T.TagName
),
UserActivity AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        MAX(B.Name) AS HighestBadgeName
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) -- bounty start or close
    LEFT JOIN
        Badges B ON U.Id = B.UserId
    GROUP BY
        U.Id, U.DisplayName
),
TopTags AS (
    SELECT
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM
        TagUsage
),
ClosedPosts AS (
    SELECT
        PH.PostId,
        PH.CreationDate,
        COUNT(*) FILTER (WHERE PH.PostHistoryTypeId = 10) AS CloseCount
    FROM
        PostHistory PH
    WHERE
        PH.PostHistoryTypeId IN (10, 11) -- Closed and Reopened
    GROUP BY
        PH.PostId, PH.CreationDate
)
SELECT
    U.DisplayName,
    U.TotalPosts,
    U.TotalBounty,
    T.TagName,
    COALESCE(C.CloseCount, 0) AS CloseCount,
    (CASE WHEN T.Rank <= 10 THEN 'Top Tag' ELSE 'Standard Tag' END) AS TagCategory,
    (SELECT COUNT(*) FROM Posts P WHERE P.OwnerUserId = U.UserId AND P.PostTypeId = 1) AS UserQuestionCount,
    (SELECT COUNT(*) FROM Posts P2 WHERE P2.OwnerUserId = U.UserId AND P2.PostTypeId = 2) AS UserAnswerCount,
    (SELECT COUNT(*) FROM Comments C WHERE C.UserId = U.UserId) AS UserCommentCount
FROM
    UserActivity U
LEFT JOIN
    TopTags T ON T.TagName = ANY(SELECT string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><') FROM Posts P WHERE P.OwnerUserId = U.UserId)
LEFT JOIN
    ClosedPosts C ON C.PostId IN (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = U.UserId)
WHERE
    U.TotalPosts > 5
ORDER BY
    U.TotalBounty DESC, U.DisplayName ASC;

This SQL query performs a complex operation by aggregating user activities, analyzing tag usage, and handling closed posts. It uses CTEs (Common Table Expressions) for cleaner code and better organization, engages in a variety of aggregations, and applies window functions. It also includes a few nested subqueries to extract specific counts related to questions, answers, and comments attributed to the users.
