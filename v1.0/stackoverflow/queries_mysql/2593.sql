
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(V.VoteTypeId = 2) AS UpVotes,
        SUM(V.VoteTypeId = 3) AS DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(P.Score) AS TotalScore
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON P.OwnerUserId = U.Id
    GROUP BY U.Id, U.DisplayName
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        PH.CreationDate AS LastEditDate,
        COALESCE(C.CreationDate, P.CreationDate) AS EffectiveCreationDate,
        CASE 
            WHEN P.ClosedDate IS NOT NULL THEN 'Closed'
            ELSE 'Open'
        END AS PostStatus,
        @row_number := IF(@current_post_id = P.Id, @row_number + 1, 1) AS EditRank,
        @current_post_id := P.Id
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN Comments C ON C.PostId = P.Id
    JOIN (SELECT @row_number := 0, @current_post_id := NULL) AS vars
    WHERE P.CreationDate > NOW() - INTERVAL 1 YEAR
)
SELECT 
    U.DisplayName as UserName,
    U.TotalPosts,
    U.TotalScore,
    COALESCE(SUM(CASE WHEN PD.PostStatus = 'Open' THEN 1 ELSE 0 END), 0) AS OpenPosts,
    COALESCE(SUM(CASE WHEN PD.PostStatus = 'Closed' THEN 1 ELSE 0 END), 0) AS ClosedPosts,
    GROUP_CONCAT(PD.Title SEPARATOR ', ') AS Titles,
    COUNT(PD.PostId) AS PostsEditedonce,
    COUNT(DISTINCT PD.PostId) AS TotalUniquePosts
FROM UserVoteStats U
LEFT JOIN PostDetails PD ON PD.OwnerDisplayName = U.DisplayName
GROUP BY U.UserId, U.DisplayName, U.TotalPosts, U.TotalScore
ORDER BY U.TotalScore DESC, U.TotalPosts DESC
LIMIT 50;
