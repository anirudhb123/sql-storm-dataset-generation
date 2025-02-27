WITH UserVotes AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(V.Id) AS TotalVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COALESCE(A.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(COALESCE(V.VoteTypeId = 2, 0)) AS UpVoteCount,
        SUM(COALESCE(V.VoteTypeId = 3, 0)) AS DownVoteCount
    FROM Posts P
    LEFT JOIN Posts A ON P.AcceptedAnswerId = A.Id
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.Title, P.CreationDate, A.AcceptedAnswerId
),
PopularTags AS (
    SELECT UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag,
           COUNT(*) AS PostCount
    FROM Posts
    GROUP BY Tag
    ORDER BY PostCount DESC
    LIMIT 5
)
SELECT 
    U.DisplayName AS UserDisplayName,
    UV.UpVotes,
    UV.DownVotes,
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.CommentCount,
    PS.UpVoteCount,
    PS.DownVoteCount,
    COALESCE(T.Tag, 'No Tags') AS PopularTag
FROM UserVotes UV
JOIN PostStats PS ON UV.TotalVotes > 0
LEFT JOIN PopularTags T ON PS.PostId IN (SELECT P.Id FROM Posts P WHERE T.Tag = ANY(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><')))
WHERE PS.CommentCount > 0
ORDER BY PS.UpVoteCount DESC, PS.CommentCount DESC
LIMIT 10;
