WITH RankedPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN C.PostId IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT A.Id) AS AnswerCount,
        STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
    FROM
        Posts P
    LEFT JOIN
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    LEFT JOIN
        Posts A ON P.Id = A.ParentId AND A.PostTypeId = 2
    LEFT JOIN
        STRING_TO_ARRAY(P.Tags, ',') AS T(TagName)
    WHERE
        P.PostTypeId = 1 -- Filtering for questions only
    GROUP BY
        P.Id, U.DisplayName
),
PostScores AS (
    SELECT
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.OwnerDisplayName,
        (RP.Score + 10 * RP.AnswerCount + 5 * RP.CommentCount + RP.ViewCount / 100) AS CompositeScore
    FROM
        RankedPosts RP
),
TopPosts AS (
    SELECT
        PS.PostId,
        PS.Title,
        PS.CreationDate,
        PS.OwnerDisplayName,
        PS.CompositeScore,
        RANK() OVER (ORDER BY PS.CompositeScore DESC) AS Rank
    FROM
        PostScores PS
)
SELECT
    TP.Rank,
    TP.Title,
    TP.PostId,
    TP.OwnerDisplayName,
    TO_CHAR(TP.CreationDate, 'YYYY-MM-DD HH24:MI:SS') AS FormattedCreationDate,
    TP.CompositeScore
FROM
    TopPosts TP
WHERE
    TP.Rank <= 10 -- Limit to top 10 posts
ORDER BY
    TP.Rank;
