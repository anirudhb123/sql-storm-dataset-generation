WITH UserWithBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName AS UserName,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        U.UserId,
        U.UserName,
        U.BadgeCount,
        U.BadgeNames,
        RANK() OVER (ORDER BY U.BadgeCount DESC) AS Rank
    FROM 
        UserWithBadges U
),
ActivePosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.OwnerUserId,
        U.DisplayName AS AuthorName,
        COUNT(C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        P.Id, P.Title, P.Body, P.CreationDate, P.Score, P.ViewCount, P.OwnerUserId, U.DisplayName
),
PostDetails AS (
    SELECT 
        A.PostId,
        A.Title,
        A.Body,
        A.CreationDate,
        A.Score,
        A.ViewCount,
        A.AuthorName,
        A.CommentCount,
        A.VoteCount,
        U.UserName AS BadgeOwner,
        U.BadgeCount AS OwnerBadgeCount,
        U.BadgeNames AS OwnerBadgeNames,
        R.Rank AS UserRank
    FROM 
        ActivePosts A
    JOIN 
        TopUsers U ON A.OwnerUserId = U.UserId
)
SELECT 
    PD.Title,
    PD.Body,
    PD.CreationDate,
    PD.Score,
    PD.ViewCount,
    PD.AuthorName,
    PD.CommentCount,
    PD.VoteCount,
    PD.BadgeOwner,
    PD.OwnerBadgeCount,
    PD.OwnerBadgeNames,
    PD.UserRank
FROM 
    PostDetails PD
WHERE 
    PD.Score > 10 AND PD.CommentCount > 5
ORDER BY 
    PD.Score DESC, PD.VoteCount DESC, PD.CreationDate DESC
LIMIT 50;
