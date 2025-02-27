WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(COUNT(DISTINCT P.Id), 0) AS PostCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId IN (10, 12) THEN 1 ELSE 0 END), 0) AS DeletedStatus
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        (EXTRACT(EPOCH FROM NOW() - P.CreationDate) / 3600) AS AgeInHours,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        AVG(P.ViewCount) OVER () AS AverageViewCount,
        COUNT(DISTINCT PH.Id) AS HistoryCount,
        STRING_AGG(DISTINCT T.TagName, ', ') AS Tags,
        (SUM(P.Score) OVER () / NULLIF(COUNT(P.Id), 0)) AS AverageScorePerPost
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN LATERAL (
        SELECT unnest(string_to_array(P.Tags, '>')) AS TagName
    ) AS T ON TRUE
    GROUP BY P.Id, P.Title, P.CreationDate
),
UserDetails AS (
    SELECT 
        A.UserId,
        A.DisplayName,
        CASE 
            WHEN A.PostCount > 10 THEN 'Active'
            WHEN A.PostCount BETWEEN 1 AND 10 THEN 'Moderate'
            WHEN A.DownVotes > A.UpVotes THEN 'Negative Feedback'
            ELSE 'Inactive'
        END AS ActivityLevel,
        (A.UpVotes - A.DownVotes) AS VoteBalance
    FROM UserActivity A
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.ActivityLevel,
    COALESCE(P.Title, 'No Posts Available') AS LatestPostTitle,
    COALESCE(P.AgeInHours, 0) AS PostAgeInHours,
    COALESCE(P.Tags, 'No Tags') AS PostTags,
    UD.VoteBalance AS UserVoteBalance,
    UD.DeletedStatus AS UserDeletedPosts,
    CASE 
        WHEN UD.VoteBalance > 0 THEN 'Positive'
        WHEN UD.VoteBalance < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS UserFeedbackStatus
FROM UserDetails UD
LEFT JOIN PostStats P ON UD.UserId = P.PostId
LEFT JOIN Users U ON U.Id = UD.UserId
ORDER BY U.Reputation DESC, UD.PostCount DESC
LIMIT 100;
