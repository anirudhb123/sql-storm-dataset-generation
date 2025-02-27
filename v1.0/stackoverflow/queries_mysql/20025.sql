
WITH UserStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.UpVotes - U.DownVotes AS NetVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoredPosts,
        @rank := IF(@prev_rank = U.Reputation, @rank, @rank + 1) AS ReputationRank,
        @prev_rank := U.Reputation
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    CROSS JOIN (SELECT @rank := 0, @prev_rank := NULL) AS vars
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.UpVotes, U.DownVotes
),
PostWithComments AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount,
        P.CreationDate,
        @user_post_num := IF(@prev_user_post_num = P.OwnerUserId, @user_post_num + 1, 1) AS UserPostNumber,
        @prev_user_post_num := P.OwnerUserId
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    CROSS JOIN (SELECT @user_post_num := 0, @prev_user_post_num := NULL) AS vars
    GROUP BY P.Id, P.Title, P.OwnerUserId, P.CreationDate
),
RankedPosts AS (
    SELECT
        PW.*,
        @comment_rank := IF(@prev_comment_count = PW.CommentCount, @comment_rank, @comment_rank + 1) AS CommentRank,
        @prev_comment_count := PW.CommentCount,
        NTILE(5) OVER (ORDER BY PW.CreationDate) AS AgeCategory
    FROM PostWithComments PW
    CROSS JOIN (SELECT @comment_rank := 0, @prev_comment_count := NULL) AS vars
),
PopularPosts AS (
    SELECT
        RP.PostId,
        RP.Title,
        U.DisplayName AS OwnerName,
        U.Reputation AS OwnerReputation,
        RP.CommentCount,
        RP.CreationDate,
        RP.CommentRank,
        CASE 
            WHEN RP.CommentCount IS NULL THEN 'No Comments' 
            WHEN RP.CommentCount > 10 THEN 'Highly Engaged' 
            ELSE 'Moderately Engaged' 
        END AS EngagementLevel
    FROM RankedPosts RP
    JOIN Users U ON RP.OwnerUserId = U.Id
    WHERE RP.CommentCount > 5 OR RP.AgeCategory = 5
)
SELECT
    PS.PostId,
    PS.Title,
    PS.OwnerName,
    PS.OwnerReputation,
    PS.CommentCount,
    PS.CreationDate,
    PS.CommentRank,
    PS.EngagementLevel,
    US.NetVotes,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = PS.PostId AND V.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = PS.PostId AND V.VoteTypeId = 3) AS DownVotes,
    DATEDIFF('2024-10-01 12:34:56', PS.CreationDate) AS AgeInDays,
    CASE
        WHEN DATEDIFF('2024-10-01 12:34:56', PS.CreationDate) <= 30 THEN 'New'
        WHEN DATEDIFF('2024-10-01 12:34:56', PS.CreationDate) <= 90 THEN 'Somewhat New'
        ELSE 'Old'
    END AS PostAgeCategory
FROM PopularPosts PS
JOIN UserStats US ON PS.OwnerName = US.DisplayName
WHERE PS.OwnerReputation BETWEEN 100 AND 1000
AND PS.CommentCount > (
    SELECT AVG(CommentCount) FROM PostWithComments
)
ORDER BY PS.CommentCount DESC, PS.CreationDate DESC
LIMIT 50;
