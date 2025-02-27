WITH RECURSIVE UserPosts AS (
    -- This CTE retrieves all posts by users along with their reputation
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        PO.Id AS PostId,
        PO.Title,
        PO.CreationDate,
        PO.Score
    FROM 
        Users U
    JOIN 
        Posts PO ON U.Id = PO.OwnerUserId
    WHERE 
        U.Reputation > 1000  -- Filter users with reputation greater than 1000
),
PostVoteCounts AS (
    -- This CTE calculates the total upvotes and downvotes for each post
    SELECT 
        P.Id AS PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),
TagStats AS (
    -- This CTE retrieves tag statistics for popular tags based on post counts
    SELECT 
        T.TagName,
        COUNT(PT.PostId) AS PostCount,
        AVG(PT.Score) AS AverageScore
    FROM 
        Tags T
    LEFT JOIN 
        Posts PT ON T.Id = PT.Id
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(PT.PostId) > 10  -- Filter for tags with more than 10 posts
),
UserPostDetails AS (
    -- This CTE combines user posts, vote counts, and tag statistics
    SELECT 
        UP.UserId,
        UP.DisplayName,
        UP.PostId,
        UP.Title,
        COALESCE(PV.UpVotes, 0) AS UpVotes,
        COALESCE(PV.DownVotes, 0) AS DownVotes,
        T.TagName AS PopularTag,
        TS.PostCount,
        TS.AverageScore
    FROM 
        UserPosts UP
    LEFT JOIN 
        PostVoteCounts PV ON UP.PostId = PV.PostId
    LEFT JOIN 
        (SELECT DISTINCT T.TagName, P.Id 
         FROM Tags T 
         INNER JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%') T ON UP.PostId = T.Id
    LEFT JOIN 
        TagStats TS ON T.TagName = TS.TagName
)
SELECT 
    U.DisplayName,
    COUNT(DISTINCT UPD.PostId) AS TotalPosts,
    SUM(UPD.UpVotes) AS TotalUpVotes,
    SUM(UPD.DownVotes) AS TotalDownVotes,
    AVG(UPD.AverageScore) AS AvgPostScore,
    STRING_AGG(DISTINCT UPD.PopularTag, ', ') AS PopularTags
FROM 
    UserPostDetails UPD
JOIN 
    Users U ON UPD.UserId = U.Id
GROUP BY 
    U.DisplayName
ORDER BY 
    TotalPosts DESC, AVG(UPD.AverageScore) DESC
LIMIT 10;  -- Limit to top 10 users based on posts
