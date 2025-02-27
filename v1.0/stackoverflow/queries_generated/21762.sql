WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(COUNT(CASE WHEN P.PostTypeId = 1 THEN P.Id END), 0) AS Questions,
        COALESCE(COUNT(CASE WHEN P.PostTypeId = 2 THEN P.Id END), 0) AS Answers,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
RankedUserActivity AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotes,
        DownVotes,
        Questions,
        Answers,
        BadgeCount,
        RANK() OVER (ORDER BY UpVotes - DownVotes DESC) AS UserRank
    FROM UserActivity
),
TopUsers AS (
    SELECT UserId, DisplayName, UpVotes, DownVotes, Questions, Answers, BadgeCount
    FROM RankedUserActivity
    WHERE UserRank <= 10
)
SELECT 
    T.DisplayName,
    T.UpVotes,
    T.DownVotes,
    T.Questions,
    T.Answers,
    T.BadgeCount,
    STRING_AGG(DISTINCT CASE WHEN PS.Id IS NOT NULL THEN PS.Title ELSE 'No Posts' END, '; ') AS PostTitles,
    AVG(COALESCE(PH.Comment, '0')) AS AvgCloseReasons,
    COUNT(DISTINCT PT.Id) AS PostTypesCount,
    ARRAY_AGG(DISTINCT C.Id) FILTER (WHERE C.UserId IS NOT NULL) AS CommentIds
FROM TopUsers T
LEFT JOIN Posts PS ON T.UserId = PS.OwnerUserId AND PS.PostTypeId IN (1, 2)
LEFT JOIN PostHistory PH ON PS.Id = PH.PostId AND PH.PostHistoryTypeId IN (10, 11)
LEFT JOIN PostTypes PT ON PS.PostTypeId = PT.Id
LEFT JOIN Comments C ON PS.Id = C.PostId
GROUP BY T.UserId, T.DisplayName
HAVING 
    SUM(CASE WHEN T.BadgeCount > 1 THEN 1 ELSE 0 END) > 0
ORDER BY T.UpVotes DESC, T.Answers DESC;
