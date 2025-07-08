
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN V.Id END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN V.Id END) AS DownVotes,
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
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY PH.CreationDate DESC) AS EditRank
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN Comments C ON C.PostId = P.Id
    WHERE P.CreationDate > DATEADD(year, -1, '2024-10-01 12:34:56'::timestamp)
)
SELECT 
    U.DisplayName as UserName,
    U.TotalPosts,
    U.TotalScore,
    COALESCE(SUM(CASE WHEN PD.PostStatus = 'Open' THEN 1 ELSE 0 END), 0) AS OpenPosts,
    COALESCE(SUM(CASE WHEN PD.PostStatus = 'Closed' THEN 1 ELSE 0 END), 0) AS ClosedPosts,
    LISTAGG(PD.Title, ', ') AS Titles,
    COUNT(CASE WHEN PD.EditRank = 1 THEN PD.PostId END) AS PostsEditedonce,
    COUNT(DISTINCT PD.PostId) AS TotalUniquePosts
FROM UserVoteStats U
LEFT JOIN PostDetails PD ON PD.OwnerDisplayName = U.DisplayName
GROUP BY U.UserId, U.DisplayName, U.TotalPosts, U.TotalScore
ORDER BY U.TotalScore DESC, U.TotalPosts DESC
LIMIT 50;
