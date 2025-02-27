WITH StringParsing AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        U.DisplayName AS OwnerDisplayName,
        (SELECT STRING_AGG(UT.Name, ', ') 
         FROM PostTypes PT 
         JOIN Votes V ON V.PostId = P.Id 
         JOIN VoteTypes VT ON V.VoteTypeId = VT.Id 
         JOIN Users UT ON V.UserId = UT.Id
         WHERE PT.Id = P.PostTypeId) AS UserVoteTypes,
        (SELECT STRING_AGG(CT.Name, ', ') 
         FROM CloseReasonTypes CT 
         JOIN PostHistory PH ON P.Id = PH.PostId 
         WHERE PH.PostHistoryTypeId = 10) AS CloseReasons,
        (SELECT COUNT(*) 
         FROM Comments C 
         WHERE C.PostId = P.Id) AS CommentCount,
        (SELECT SUM(V.BountyAmount) 
         FROM Votes V 
         WHERE V.PostId = P.Id AND V.VoteTypeId IN (8, 9)) AS TotalBounty,
        ARRAY_LENGTH(string_to_array(P.Tags, '>'), 1) AS TagCount
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= '2022-01-01'
    GROUP BY 
        P.Id, U.DisplayName
)
SELECT 
    SP.PostId,
    SP.Title,
    SP.OwnerDisplayName,
    SP.UserVoteTypes,
    SP.CloseReasons,
    SP.CommentCount,
    SP.TotalBounty,
    SP.TagCount
FROM 
    StringParsing SP
WHERE 
    SP.CommentCount > 10
ORDER BY 
    SP.TagCount DESC, SP.TotalBounty DESC
LIMIT 100;
