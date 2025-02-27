WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        U.DisplayName AS OwnerDisplayName,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM
        Posts p
    JOIN
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN
        Tags T ON T.Id IN (SELECT UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><')))
        WHERE T.TagName IS NOT NULL
    GROUP BY
        p.Id, U.DisplayName
),
TopRatedPosts AS (
    SELECT
        RP.PostId,
        RP.Title,
        RP.Body,
        RP.CreationDate,
        RP.ViewCount,
        RP.Score,
        RP.OwnerDisplayName,
        RP.TagList
    FROM
        RankedPosts RP
    WHERE
        RP.PostRank <= 5
),
PostComments AS (
    SELECT
        C.PostId,
        C.UserDisplayName,
        C.Text AS CommentText,
        C.CreationDate AS CommentDate
    FROM
        Comments C
    WHERE
        C.PostId IN (SELECT PostId FROM TopRatedPosts)
),
CommentCount AS (
    SELECT
        PostId,
        COUNT(*) AS TotalComments
    FROM
        PostComments
    GROUP BY
        PostId
)
SELECT
    TRP.PostId,
    TRP.Title,
    TRP.Body,
    TRP.CreationDate AS PostCreationDate,
    TRP.ViewCount,
    TRP.Score,
    TRP.OwnerDisplayName,
    TRP.TagList,
    COALESCE(CC.TotalComments, 0) AS CommentCount
FROM
    TopRatedPosts TRP
LEFT JOIN
    CommentCount CC ON TRP.PostId = CC.PostId
ORDER BY
    TRP.Score DESC, TRP.ViewCount DESC;
