WITH PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS DownVoteCount,
        STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(P.Tags FROM 2 FOR LENGTH(P.Tags) - 2), '><') AS TagArray
    LEFT JOIN 
        Tags T ON T.TagName = TagArray.value
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, U.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        PH.Comment,
        PH.CreationDate AS HistoryDate,
        P.Title AS PostTitle,
        PH.UserDisplayName AS EditedBy,
        P.OwnerDisplayName,
        SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN PH.PostHistoryTypeId = 12 THEN 1 ELSE 0 END) AS DeleteCount
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    JOIN 
        PostDetails PD ON P.Id = PD.PostId
    GROUP BY 
        PH.PostId, P.Title, PH.UserDisplayName, PD.OwnerDisplayName, PH.CreationDate
),
FinalDetails AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.CreationDate,
        PD.OwnerDisplayName,
        PD.CommentCount,
        PD.UpVoteCount,
        PD.DownVoteCount,
        PD.Tags,
        PH.HistoryDate,
        PH.EditedBy,
        PH.OwnerDisplayName AS EditorPostOwner,
        PH.CloseCount,
        PH.DeleteCount
    FROM 
        PostDetails PD
    LEFT JOIN 
        PostHistoryDetails PH ON PD.PostId = PH.PostId
)
SELECT 
    FD.*,
    (FD.UpVoteCount - FD.DownVoteCount) AS NetScore,
    CASE 
        WHEN FD.CloseCount > 0 THEN 'Closed' 
        ELSE 'Open' 
    END AS PostStatus,
    date_part('epoch', FD.CreationDate) AS CreationTimestamp
FROM 
    FinalDetails FD
ORDER BY 
    FD.CreationDate DESC, 
    NetScore DESC;
