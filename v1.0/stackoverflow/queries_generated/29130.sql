WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
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
        P.PostTypeId,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.ViewCount,
        COALESCE(P.AnswerCount, 0) AS AnswerCount,
        COALESCE(P.CommentCount, 0) AS CommentCount,
        STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(P.Tags, 2, LENGTH(P.Tags) - 2), '><') AS TagArray ON TRUE
    LEFT JOIN 
        Tags T ON T.TagName = TagArray.value
    GROUP BY 
        P.Id, U.DisplayName
),
VoteDetails AS (
    SELECT 
        V.PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN V.VoteTypeId = 6 THEN 1 END) AS CloseVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
)
SELECT 
    UBC.UserId,
    UBC.DisplayName AS UserDisplayName,
    UBC.BadgeCount,
    UBC.BadgeNames,
    PD.PostId,
    PD.Title AS PostTitle,
    PD.PostTypeId,
    PD.OwnerDisplayName,
    PD.CreationDate,
    PD.ViewCount,
    PD.AnswerCount,
    PD.CommentCount,
    PD.Tags,
    VD.UpVotes,
    VD.DownVotes,
    VD.CloseVotes
FROM 
    UserBadgeCounts UBC
JOIN 
    PostDetails PD ON UBC.UserId = PD.OwnerDisplayName
JOIN 
    VoteDetails VD ON PD.PostId = VD.PostId
WHERE 
    UBC.BadgeCount > 0
ORDER BY 
    UBC.BadgeCount DESC, PD.ViewCount DESC;
