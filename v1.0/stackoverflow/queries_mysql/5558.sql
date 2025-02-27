
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
UserRanked AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        Questions,
        Answers,
        CommentCount,
        UpVotes,
        DownVotes,
        BadgeCount,
        @postRank := IF(@prevPostCount = PostCount, @postRank, @rowNum) AS PostRank,
        @rowNum := @rowNum + 1,
        @prevPostCount := PostCount,
        @upVoteRank := IF(@prevUpVotes = UpVotes, @upVoteRank, @upVoteRowNum) AS UpVoteRank,
        @upVoteRowNum := @upVoteRowNum + 1,
        @prevUpVotes := UpVotes
    FROM UserActivity, (SELECT @rowNum := 1, @postRank := 1, @prevPostCount := NULL, @upVoteRowNum := 1, @upVoteRank := 1, @prevUpVotes := NULL) AS vars
    ORDER BY PostCount DESC, UpVotes DESC
)
SELECT 
    DisplayName,
    PostCount,
    Questions,
    Answers,
    CommentCount,
    UpVotes,
    DownVotes,
    BadgeCount,
    PostRank,
    UpVoteRank
FROM UserRanked
WHERE PostCount > 5 
ORDER BY PostRank, UpVotes DESC
LIMIT 10;
