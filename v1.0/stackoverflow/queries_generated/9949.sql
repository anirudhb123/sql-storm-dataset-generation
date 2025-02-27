SELECT 
    P.Title AS Post_Title,
    U.DisplayName AS Owner_DisplayName,
    P.Score AS Post_Score,
    COALESCE(PV.UpVotes, 0) AS Post_UpVotes,
    COALESCE(PV.DownVotes, 0) AS Post_DownVotes,
    C.CommentCount,
    T.TagName,
    PH.CreationDate AS Last_Edited,
    P.LastActivityDate,
    COUNT(DISTINCT C.Id) AS Total_Comments,
    COUNT(DISTINCT B.Id) AS Total_Badges,
    COUNT(DISTINCT PL.RelatedPostId) AS Total_Links
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Votes PV ON P.Id = PV.PostId AND PV.VoteTypeId IN (2, 3) 
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Tags T ON T.WikiPostId = P.Id OR T.ExcerptPostId = P.Id
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId 
LEFT JOIN 
    Badges B ON U.Id = B.UserId
LEFT JOIN 
    PostLinks PL ON P.Id = PL.PostId
WHERE 
    P.CreationDate >= '2023-01-01'
GROUP BY 
    P.Id, U.DisplayName, PV.UpVotes, PV.DownVotes, C.CommentCount, T.TagName, PH.CreationDate
ORDER BY 
    P.LastActivityDate DESC
LIMIT 
    100;
