WITH RankedPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM
        Posts P
    WHERE
        P.PostTypeId = 1 AND P.Score > 0
),
FilteredVotes AS (
    SELECT
        V.PostId,
        COUNT(*) AS VoteCount
    FROM
        Votes V
    WHERE
        V.VoteTypeId IN (2, 3) -- UpVotes and DownVotes
    GROUP BY
        V.PostId
),
UsersWithBadges AS (
    SELECT
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount
    FROM
        Users U
    LEFT JOIN
        Badges B ON U.Id = B.UserId
    WHERE
        U.Reputation > 50
    GROUP BY
        U.Id
)
SELECT
    P.Title,
    P.CreationDate,
    P.Score,
    COALESCE(FV.VoteCount, 0) AS TotalVotes,
    COALESCE(UW.BadgeCount, 0) AS TotalBadges
FROM
    RankedPosts P
LEFT JOIN
    FilteredVotes FV ON P.PostId = FV.PostId
LEFT JOIN
    UsersWithBadges UW ON P.OwnerUserId = UW.UserId
WHERE
    P.PostRank = 1
    AND (P.Score + COALESCE(FV.VoteCount, 0)) > 10
ORDER BY
    P.CreationDate DESC
LIMIT 10;

WITH PostDetails AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.LastActivityDate,
        COUNT(C.Id) AS CommentCount
    FROM
        Posts P
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    GROUP BY
        P.Id
)
SELECT
    PD.PostId,
    PD.Title,
    RIGHT(PD.Body, 100) AS BodySnippet,
    PD.LastActivityDate,
    CASE 
        WHEN PD.CommentCount > 0 THEN 'Has Comments'
        ELSE 'No Comments'
    END AS CommentStatus
FROM
    PostDetails PD
WHERE
    PD.LastActivityDate >= NOW() - INTERVAL '30 days'
ORDER BY
    PD.LastActivityDate DESC;
