WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(COALESCE(V.VoteTypeId = 2, 0)) AS TotalUpVotes,
        SUM(COALESCE(V.VoteTypeId = 3, 0)) AS TotalDownVotes,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBountyAmount,
        RANK() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON C.UserId = U.Id
    LEFT JOIN 
        Votes V ON V.UserId = U.Id
    WHERE 
        U.Reputation > 1000 -- Filter for active users with reputation above 1000
    GROUP BY 
        U.Id, U.DisplayName
)

SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.TotalPosts,
    UA.TotalComments,
    UA.TotalUpVotes,
    UA.TotalDownVotes,
    UA.TotalBountyAmount,
    COALESCE(NULLIF(NULLIF(UA.TotalPosts, 0), 0) / NULLIF(UA.TotalComments, 0), 0) AS PostCommentRatio,
    CASE 
        WHEN UA.TotalUpVotes > UA.TotalDownVotes THEN 'Positive' 
        WHEN UA.TotalUpVotes < UA.TotalDownVotes THEN 'Negative' 
        ELSE 'Neutral'
    END AS VoteSentiment,
    SH.TagName AS MostUsedTag,
    PHT.Name AS LastPostHistoryAction
FROM 
    UserActivity UA
LEFT JOIN 
    (SELECT 
        P.OwnerUserId,
        T.TagName,
        COUNT(*) AS TagCount
     FROM 
        Posts P
     CROSS JOIN 
        Tags T ON POSITION('|' || T.TagName || '|' IN '|' || P.Tags || '|') > 0
     GROUP BY 
        P.OwnerUserId, T.TagName
     ORDER BY 
        TagCount DESC 
     LIMIT 1) SH ON UA.UserId = SH.OwnerUserId
LEFT JOIN 
    (SELECT 
        PH.UserId,
        PH.PostId,
        PHT.Name
     FROM 
        PostHistory PH
     JOIN 
        PostHistoryTypes PHT ON PHT.Id = PH.PostHistoryTypeId
     WHERE 
        PH.CreationDate = (SELECT MAX(CreationDate) FROM PostHistory WHERE UserId = PH.UserId)
    ) AS PH ON UA.UserId = PH.UserId
WHERE 
    UA.UserRank <= 10 -- Get top 10 users
ORDER BY 
    UA.UserRank;

This query generates a user's activity report including metrics like the total number of posts, comments, upvotes, downvotes, and bounty amounts for users with a reputation above 1000. It also calculates the ratio of posts to comments, determines the vote sentiment, retrieves the most used tag from their posts, and the last action taken on their most recent posts, using CTEs, window functions, outer joins, conditional logic, and NULL handling.
