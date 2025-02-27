WITH RankedPosts AS (
    SELECT
        Posts.Id AS PostId,
        Posts.Title,
        Posts.Body,
        Posts.Tags,
        Posts.CreationDate,
        Posts.ViewCount,
        Posts.Score,
        U.DisplayName AS OwnerDisplayName,
        PHT.PostHistoryTypeId,
        PHT.CreationDate AS HistoryCreationDate,
        RANK() OVER (PARTITION BY Posts.Id ORDER BY PHT.CreationDate DESC) AS Rank
    FROM
        Posts 
    JOIN 
        Users U ON Posts.OwnerUserId = U.Id
    LEFT JOIN 
        PostHistory PHT ON Posts.Id = PHT.PostId
    WHERE
        Posts.PostTypeId = 1
        AND Posts.Title IS NOT NULL
        AND Posts.Body IS NOT NULL
),
PostTagCounts AS (
    SELECT
        PostId,
        COUNT(*) AS TagCount
    FROM 
        (
            SELECT 
                PostId,
                unnest(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags) - 2), '><')) AS Tag
            FROM 
                Posts
            WHERE 
                Posts.PostTypeId = 1
        ) AS Tags
    GROUP BY PostId
),
UserActivity AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT V.Id) AS VoteCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY
        U.Id, U.DisplayName
)
SELECT
    RP.PostId,
    RP.Title,
    RP.Body,
    RP.Tags,
    RP.CreationDate,
    RP.ViewCount,
    RP.Score,
    RP.OwnerDisplayName,
    PTC.TagCount,
    UA.DisplayName AS UserDisplayName,
    UA.VoteCount,
    UA.CommentCount,
    UA.BadgeCount,
    COALESCE(PHT.Comment, PHT.Text) AS LastActionComment,
    RP.HistoryCreationDate
FROM
    RankedPosts RP
JOIN 
    PostTagCounts PTC ON RP.PostId = PTC.PostId
JOIN 
    UserActivity UA ON RP.PostId = UA.UserId
LEFT JOIN 
    PostHistory PHT ON RP.PostId = PHT.PostId
WHERE
    RP.Rank = 1
ORDER BY 
    RP.Score DESC,
    PTC.TagCount DESC,
    RP.CreationDate DESC
LIMIT 10;
