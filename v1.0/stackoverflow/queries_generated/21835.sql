WITH UserStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        RANK() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM
        Users U
    LEFT JOIN
        Votes V ON U.Id = V.UserId
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY
        U.Id
),
PostDetails AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AcceptedAnswerId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        (SELECT COUNT(*) FROM Votes WHERE PostId = P.Id) AS VoteCount,
        STRING_AGG(DISTINCT T.TagName, ', ') AS Tags,
        P.OwnerUserId,
        U.DisplayName AS OwnerDisplayName
    FROM
        Posts P
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    JOIN
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN
        LATERAL string_to_array(P.Tags, ',') AS tag ON true
    LEFT JOIN
        Tags T ON T.TagName = tag
    WHERE
        P.Score > 0
    GROUP BY
        P.Id, U.DisplayName
),
CloseDetails AS (
    SELECT
        PH.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(CASE WHEN PHT.Comment IS NULL THEN 'No Comment' ELSE PHT.Comment END, '; ') AS CloseComments,
        MAX(PH.CreationDate) AS LastClosedDate
    FROM
        PostHistory PH
    JOIN
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE
        PHT.Name = 'Post Closed'
    GROUP BY
        PH.PostId
)
SELECT
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.Score,
    PS.CommentCount,
    PS.VoteCount,
    PS.Tags,
    ST.UserId,
    ST.DisplayName,
    ST.Reputation,
    ST.TotalBounties,
    ST.TotalPosts,
    COALESCE(CD.CloseCount, 0) AS CloseCount,
    CD.LastClosedDate
FROM
    PostDetails PS
JOIN
    UserStats ST ON PS.OwnerUserId = ST.UserId
LEFT JOIN
    CloseDetails CD ON PS.PostId = CD.PostId
WHERE
    ST.Reputation > 1000 
    AND (CD.CloseCount IS NULL OR CD.CloseCount < 3)
ORDER BY
    ST.TotalPosts DESC, PS.Score DESC
LIMIT 50;
