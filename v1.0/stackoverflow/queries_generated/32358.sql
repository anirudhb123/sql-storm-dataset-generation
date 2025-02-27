WITH RECURSIVE UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        B.Name AS BadgeName,
        B.Date,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY B.Date DESC) AS BadgeRank
    FROM 
        Users U
    JOIN 
        Badges B ON U.Id = B.UserId
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= DATEADD(DAY, -30, GETDATE())
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, U.DisplayName
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate AS ClosedDate,
        PH.UserDisplayName AS ClosedBy,
        C.Name AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes C ON PH.Comment::integer = C.Id
    WHERE 
        PH.PostHistoryTypeId = 10
)
SELECT 
    UP.UserId,
    UP.DisplayName,
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.CommentCount,
    RP.UpVotes,
    RP.DownVotes,
    CB.ClosedDate,
    CB.ClosedBy,
    CB.CloseReason,
    B.BadgeName,
    CASE 
        WHEN RP.Score >= 100 THEN 'High Score'
        WHEN RP.Score >= 50 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    UserBadges B
JOIN 
    Users UP ON B.UserId = UP.Id
JOIN 
    RecentPosts RP ON UP.Id = RP.OwnerDisplayName
LEFT JOIN 
    ClosedPosts CB ON RP.PostId = CB.PostId
WHERE 
    B.BadgeRank <= 3
    AND RP.CommentCount > 5
ORDER BY 
    RP.Score DESC,
    RP.CreationDate DESC;
