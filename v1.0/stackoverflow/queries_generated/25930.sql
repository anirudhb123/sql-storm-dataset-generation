WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        U.DisplayName AS OwnerName,
        COUNT(C.CommentId) AS TotalComments,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS Upvotes,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS Downvotes,
        RANK() OVER (ORDER BY COUNT(C.CommentId) DESC, P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        (SELECT PostId, COUNT(Id) AS CommentId FROM Comments GROUP BY PostId) C ON P.Id = C.PostId
    WHERE 
        P.PostTypeId = 1 -- Considering only Questions
    GROUP BY 
        P.Id, P.Title, P.Body, P.CreationDate, U.DisplayName
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(PT.PostId) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%' -- Assuming tags are stored in a comma-separated text format
    JOIN 
        PostHistory PH ON PH.PostId = P.Id
    WHERE 
        P.PostTypeId = 1 -- Considering only Questions
    GROUP BY 
        T.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
)
SELECT 
    RP.PostId, 
    RP.Title, 
    RP.Body, 
    RP.CreationDate, 
    RP.OwnerName, 
    RP.TotalComments, 
    RP.Upvotes, 
    RP.Downvotes, 
    ARRAY_AGG(T.TagName) AS Tags 
FROM 
    RankedPosts RP
LEFT JOIN 
    Tags T ON RP.Tags LIKE '%' || T.TagName || '%' -- Join to get tags for each post
WHERE 
    RP.Rank <= 10 -- Fetching top 10 posts based on rank
GROUP BY 
    RP.PostId, RP.Title, RP.Body, RP.CreationDate, RP.OwnerName, RP.TotalComments, RP.Upvotes, RP.Downvotes
ORDER BY 
    RP.TotalComments DESC, RP.CreationDate DESC;
This query retrieves the top 10 questions based on the number of comments and their creation date, along with related metrics such as upvotes and downvotes, while also aggregating the associated tags. It leverages common table expressions (CTEs) to break down the query into manageable sections.
