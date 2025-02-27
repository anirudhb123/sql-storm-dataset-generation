WITH RecursiveBadges AS (
    SELECT U.Id AS UserId, U.DisplayName, B.Name AS BadgeName, B.Class, 
           ROW_NUMBER() OVER(PARTITION BY U.Id ORDER BY B.Date DESC) AS BadgeRank
    FROM Users U
    INNER JOIN Badges B ON U.Id = B.UserId
),
PostInfo AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        COALESCE(P.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(CASE WHEN C.PostId IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(V.VoteTypeId = 2) AS UpVotes,
        SUM(V.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER(PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id
),
PostHistoryInfo AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS HistoryCount,
        MAX(PH.CreationDate) AS LastModified,
        STRING_AGG(PHT.Name, ', ') AS HistoryTypes
    FROM PostHistory PH
    INNER JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY PH.PostId
)

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COALESCE(B.BadgeName, 'No Badge') AS Badge,
    B.Class AS BadgeClass,
    P.PostId,
    P.Title,
    P.CreationDate AS PostCreationDate,
    P.CommentCount,
    P.UpVotes,
    P.DownVotes,
    PH.HistoryCount,
    PH.LastModified,
    PH.HistoryTypes,
    CASE 
        WHEN P.AcceptedAnswerId > 0 THEN 'Accepted Answer Found'
        ELSE 'No Accepted Answer'
    END AS AcceptedAnswerStatus
FROM Users U
LEFT JOIN RecursiveBadges B ON U.Id = B.UserId AND B.BadgeRank = 1 -- Top badge
JOIN PostInfo P ON U.Id = P.OwnerUserId
LEFT JOIN PostHistoryInfo PH ON P.PostId = PH.PostId
WHERE U.Reputation > 1000 -- Filter for users with a reputation over 1000
ORDER BY U.Reputation DESC, P.CommentCount DESC;

This SQL query performs several complex operations to extract detailed information about users, their posts, badges, and post history while applying various SQL constructs such as CTEs (Common Table Expressions), window functions, outer joins, and conditional expressions. The query showcases how users with significant contributions are highlighted along with the latest activity on their posts and their respective badge details.
