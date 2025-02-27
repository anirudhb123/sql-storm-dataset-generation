
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        GROUP_CONCAT(B.Name SEPARATOR ', ') AS Badges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation AS OwnerReputation,
        COUNT(C.Id) AS CommentCount,
        GROUP_CONCAT(DISTINCT T.TagName SEPARATOR ', ') AS Tags,
        P.Body
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', n.n), '><', -1) AS tag_name
         FROM Posts P
         JOIN (SELECT @row := @row + 1 AS n FROM 
               (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) t1,
               (SELECT @row := 0) t2) n
         WHERE CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) >= n.n - 1) AS tag_name 
    ON TRUE
    LEFT JOIN 
        Tags T ON tag_name = T.TagName
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, U.DisplayName, U.Reputation, P.Body
),
PopularPosts AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.CreationDate,
        PD.Score,
        PD.OwnerDisplayName,
        PD.OwnerReputation,
        PD.CommentCount,
        PD.Tags,
        PD.Body,
        @rownum := @rownum + 1 AS Rank
    FROM 
        PostDetails PD, (SELECT @rownum := 0) r
    ORDER BY 
        PD.Score DESC
)
SELECT 
    UB.UserId,
    UB.DisplayName,
    UB.BadgeCount,
    UB.Badges,
    PP.Title AS PopularPostTitle,
    PP.CreationDate AS PostDate,
    PP.OwnerReputation,
    PP.CommentCount,
    PP.Tags
FROM 
    UserBadges UB
JOIN 
    PopularPosts PP ON PP.Rank <= 10 AND PP.OwnerDisplayName = UB.DisplayName
ORDER BY 
    UB.BadgeCount DESC, PP.Score DESC;
