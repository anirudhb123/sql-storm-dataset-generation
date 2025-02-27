WITH PostMeta AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 10 THEN 1 ELSE 0 END), 0) AS DeletionVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT PL.RelatedPostId) AS RelatedPosts,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RN,
        (SELECT COUNT(*) FROM Comments WHERE PostId = P.Id) AS TotalComments
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostLinks PL ON P.Id = PL.PostId
    WHERE 
        P.CreationDate >= DATEADD(MONTH, -6, GETDATE()) 
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount
),
FilteredPosts AS (
    SELECT 
        PM.PostId,
        PM.Title,
        PM.CreationDate,
        PM.ViewCount,
        PM.UpVotes,
        PM.DownVotes,
        PM.DeletionVotes,
        PM.CommentCount,
        PM.RelatedPosts,
        PM.TotalComments,
        CASE 
            WHEN PM.UpVotes > PM.DownVotes THEN 'Positive'
            WHEN PM.UpVotes < PM.DownVotes THEN 'Negative'
            ELSE 'Neutral'
        END AS Sentiment,
        (SELECT STRING_AGG(CAST(T.TagName AS varchar), ', ') 
         FROM Tags T 
         WHERE T.Id IN (SELECT Unnest(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><'))::int)) 
         LIMIT 5) AS SampleTags
    FROM 
        PostMeta PM
    WHERE 
        PM.UpVotes - PM.DownVotes > 10
        AND PM.CommentCount > 0
),
FinalOutput AS (
    SELECT 
        FP.*,
        PT.Name AS PostType,
        U.DisplayName AS Author,
        CASE 
            WHEN FP.RelatedPosts > 0 THEN 'Has related links'
            ELSE 'No related links'
        END AS RelationStatus
    FROM 
        FilteredPosts FP
    JOIN 
        PostTypes PT ON FP.PostId = PT.Id
    JOIN 
        Users U ON U.Id = (SELECT OwnerUserId FROM Posts WHERE Id = FP.PostId)
)
SELECT 
    *,
    CASE 
        WHEN TotalComments > 50 THEN 'Hot'
        ELSE 'Cold'
    END AS Activity
FROM 
    FinalOutput
WHERE 
    (SELECT COUNT(*) FROM Badges B WHERE B.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = FinalOutput.PostId)) > 2
ORDER BY 
    CreationDate DESC, UpVotes DESC;
