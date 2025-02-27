WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.Comment) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY P.Tags ORDER BY P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId IN (1, 2) -- Filtering for questions and answers
    GROUP BY 
        P.Id, P.Title, P.Body, P.CreationDate, U.DisplayName
),

TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Body,
        RP.CreationDate,
        RP.OwnerDisplayName,
        RP.CommentCount,
        RP.UpVotes,
        RP.DownVotes
    FROM 
        RankedPosts RP
    WHERE 
        RP.Rank <= 5 -- Top 5 posts per tag
)

SELECT 
    TP.Title AS PostTitle,
    TP.Body AS PostBody,
    TP.CreationDate,
    TP.OwnerDisplayName,
    TP.CommentCount,
    TP.UpVotes,
    TP.DownVotes,
    T.TagName,
    PH.DisplayName AS LastEditor,
    PH.CreationDate AS LastEditDate
FROM 
    TopPosts TP
JOIN 
    Tags T ON TP.Tags LIKE '%' || T.TagName || '%'
LEFT JOIN 
    Posts P2 ON TP.PostId = P2.Id
LEFT JOIN 
    (SELECT 
        PostId, 
        UserDisplayName AS DisplayName, 
        CreationDate 
     FROM 
        PostHistory 
     WHERE 
        PostHistoryTypeId = 24 -- Suggested Edit Applied
    ) AS PH ON TP.PostId = PH.PostId
ORDER BY 
    TP.CreationDate DESC;
