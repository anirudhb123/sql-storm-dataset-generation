WITH PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        U.DisplayName AS Owner,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        STRING_AGG(T.TagName, ', ') AS Tags
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        UNNEST(string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><')) AS TagName ON T.TagName = TagName
    GROUP BY 
        P.Id, P.Title, P.Body, P.CreationDate, U.DisplayName, P.Score, P.ViewCount, P.AnswerCount, P.CommentCount, P.FavoriteCount
),
MostVotedPosts AS (
    SELECT 
        PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,  -- Count upvotes
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes -- Count downvotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
),
PostHistoryChanges AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        COUNT(PH.Id) AS ChangeCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11, 12, 14) -- Only count relevant changes
    GROUP BY 
        PH.PostId, PH.PostHistoryTypeId
),
AggregatedChanges AS (
    SELECT 
        PHC.PostId,
        SUM(PHC.ChangeCount) AS TotalChanges
    FROM 
        PostHistoryChanges PHC
    GROUP BY 
        PHC.PostId
)
SELECT 
    PD.PostId,
    PD.Title,
    PD.Owner,
    PD.CreationDate,
    PD.Score,
    PD.ViewCount,
    PD.AnswerCount,
    PD.CommentCount,
    PD.FavoriteCount,
    MV.Upvotes,
    MV.Downvotes,
    AC.TotalChanges,
    PD.Tags
FROM 
    PostDetails PD
JOIN 
    MostVotedPosts MV ON PD.PostId = MV.PostId
LEFT JOIN 
    AggregatedChanges AC ON PD.PostId = AC.PostId
WHERE 
    PD.ViewCount > 1000 -- Filter for posts with significant views
ORDER BY 
    MV.Upvotes DESC, PD.CreationDate DESC
LIMIT 10; -- Limit results to top 10 posts
    
