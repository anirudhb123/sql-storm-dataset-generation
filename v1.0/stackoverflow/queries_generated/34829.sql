WITH RecursivePostHierarchy AS (
    SELECT 
        Id AS PostId,
        Title,
        CreationDate,
        Score,
        OwnerUserId,
        ParentId,
        0 AS Level
    FROM Posts
    WHERE ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        p.ParentId,
        r.Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpVoteCount,
        DownVoteCount,
        PostCount,
        BadgeCount,
        CommentCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM UserStatistics
),
PostsWithComments AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        COALESCE(C.CommentCount, 0) AS CommentCount,
        COALESCE(PH.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        P.CreationDate
    FROM Posts P
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) C ON P.Id = C.PostId
    LEFT JOIN Posts PH ON P.AcceptedAnswerId = PH.Id
)
SELECT 
    PH.PostId,
    PH.Title,
    PH.CreationDate,
    PH.Score,
    COALESCE(PH.CommentCount, 0) AS TotalComments,
    COALESCE(R.ParentId, 0) AS ParentId,
    TU.DisplayName AS TopUser
FROM PostsWithComments PH
LEFT JOIN RecursivePostHierarchy R ON PH.PostId = R.PostId
JOIN TopUsers TU ON PH.PostId IN (
    SELECT DISTINCT P.Id
    FROM Posts P
    JOIN UserStatistics US ON P.OwnerUserId = US.UserId
    WHERE US.Rank <= 10
)
WHERE PH.Score > 0
ORDER BY PH.Score DESC, PH.CreationDate DESC;

