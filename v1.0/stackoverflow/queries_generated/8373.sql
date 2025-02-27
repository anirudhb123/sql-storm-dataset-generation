WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.Views, U.UpVotes, U.DownVotes
),
PostVoteStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        V.VoteTypeId,
        COUNT(V.Id) AS VoteCount
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY P.Id, P.Title, V.VoteTypeId
),
TopTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY T.TagName
    ORDER BY PostCount DESC
    LIMIT 10
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.Views,
    U.UpVotes,
    U.DownVotes,
    U.PostCount,
    U.QuestionCount,
    U.AnswerCount,
    COALESCE(SUM(CASE WHEN PVS.VoteTypeId = 2 THEN PVS.VoteCount ELSE 0 END), 0) AS TotalUpvotes,
    COALESCE(SUM(CASE WHEN PVS.VoteTypeId = 3 THEN PVS.VoteCount ELSE 0 END), 0) AS TotalDownvotes,
    T.TagName,
    T.PostCount AS TagPostCount
FROM UserStats U
LEFT JOIN PostVoteStats PVS ON U.UserId = PVS.PostId
LEFT JOIN TopTags T ON T.TagName IN (SELECT unnest(string_to_array(U.Tags, ',')))
GROUP BY U.UserId, U.DisplayName, U.Reputation, U.Views, U.UpVotes, U.DownVotes, U.PostCount, U.QuestionCount, U.AnswerCount, T.TagName, T.PostCount
ORDER BY U.Reputation DESC
LIMIT 50;
