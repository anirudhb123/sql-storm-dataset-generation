
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        GROUP_CONCAT(B.Name SEPARATOR ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        P.OwnerUserId,
        P.Score,
        P.ViewCount,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        GROUP_CONCAT(DISTINCT T.TagName SEPARATOR ', ') AS TagList
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', n.n), '><', -1)) AS TagName
            FROM (SELECT @rownum:=@rownum+1 AS n FROM 
                (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
                UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) t,
                (SELECT @rownum:=-1) r) n
            WHERE n.n <= CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) + 1) T
    ON TRUE
    GROUP BY 
        P.Id, P.Title, P.Body, P.Tags, P.OwnerUserId, P.Score, P.ViewCount
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate AS ClosedDate,
        P.Title,
        P.Body
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.PostHistoryTypeId = 10
),
RankedPosts AS (
    SELECT 
        PM.*,
        @rownum := @rownum + 1 AS Ranking
    FROM 
        PostMetrics PM, (SELECT @rownum := 0) r
    ORDER BY 
        PM.Score DESC, PM.ViewCount DESC, PM.CommentCount DESC
)
SELECT 
    RP.Ranking,
    RP.Title,
    RP.PostId,
    RP.Body,
    RP.TagList,
    U.DisplayName AS OwnerDisplayName,
    UBad.BadgeCount,
    UBad.BadgeNames,
    CP.ClosedDate
FROM 
    RankedPosts RP
JOIN 
    Users U ON RP.OwnerUserId = U.Id
LEFT JOIN 
    UserBadges UBad ON U.Id = UBad.UserId
LEFT JOIN 
    ClosedPosts CP ON RP.PostId = CP.PostId
WHERE 
    RP.Ranking <= 10 
ORDER BY 
    RP.Ranking;
