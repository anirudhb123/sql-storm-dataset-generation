WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        P.OwnerDisplayName,
        U.Reputation,
        COUNT(PC.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments PC ON P.Id = PC.PostId
    WHERE 
        P.PostTypeId = 1  -- Considering only Questions
        AND P.CreationDate >= DATEADD(YEAR, -1, GETDATE())  -- Posts from the last year
    GROUP BY 
        P.Id, P.Title, P.Body, P.Tags, P.OwnerDisplayName, U.Reputation
),

TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Body,
        RP.Tags,
        RP.OwnerDisplayName,
        RP.Reputation,
        RP.CommentCount,
        NTILE(5) OVER (ORDER BY RP.Reputation DESC) AS ReputationQuartile
    FROM 
        RankedPosts RP
)

SELECT 
    TP.PostId,
    TP.Title,
    TP.Body,
    STRING_AGG(T.TagName, ', ') AS TagList,
    TP.OwnerDisplayName,
    TP.Reputation,
    TP.CommentCount,
    COUNT(V.Id) AS VoteCount
FROM 
    TopPosts TP
LEFT JOIN 
    Tags T ON T.Id = ANY(STRING_TO_ARRAY(TP.Tags, ','))
LEFT JOIN 
    Votes V ON V.PostId = TP.PostId
GROUP BY 
    TP.PostId, TP.Title, TP.Body, TP.OwnerDisplayName, TP.Reputation, TP.CommentCount
HAVING 
    COUNT(V.Id) > 10  -- Posts with more than 10 votes
ORDER BY 
    TP.Reputation DESC, 
    TP.CommentCount DESC
LIMIT 100;  -- Limit to top 100 posts

