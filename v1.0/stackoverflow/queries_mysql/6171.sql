
WITH PostDetails AS (
    SELECT 
        P.Id AS PostID,
        P.Title,
        P.Body,
        U.DisplayName AS OwnerName,
        P.CreationDate,
        P.LastActivityDate,
        COALESCE(PH.Comment, 'No comments') AS LastEditComment,
        PH.CreationDate AS LastEditDate,
        COUNT(CMP.Id) AS CommentCount,
        COUNT(CASE WHEN VO.VoteTypeId = 2 THEN VO.Id END) AS Upvotes,
        COUNT(CASE WHEN VO.VoteTypeId = 3 THEN VO.Id END) AS Downvotes
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.CreationDate = (
            SELECT MAX(PH2.CreationDate) 
            FROM PostHistory PH2 
            WHERE PH2.PostId = P.Id
        )
    LEFT JOIN 
        Comments CMP ON P.Id = CMP.PostId
    LEFT JOIN 
        Votes VO ON P.Id = VO.PostId
    GROUP BY 
        P.Id, P.Title, P.Body, U.DisplayName, P.CreationDate, P.LastActivityDate, PH.Comment, PH.CreationDate
),
RankedPosts AS (
    SELECT 
        PD.*,
        @rownum := @rownum + 1 AS Rank
    FROM 
        PostDetails PD, (SELECT @rownum := 0) r
    ORDER BY 
        PD.Upvotes DESC, PD.LastActivityDate DESC
)
SELECT 
    RP.PostID,
    RP.Title,
    RP.OwnerName,
    RP.CreationDate,
    RP.LastActivityDate,
    RP.LastEditComment,
    RP.LastEditDate,
    RP.CommentCount,
    RP.Upvotes,
    RP.Downvotes
FROM 
    RankedPosts RP
WHERE 
    RP.Rank <= 10
ORDER BY 
    RP.Rank;
