WITH RECURSIVE MostActiveUsers AS (
    -- Recursive CTE to find users with most posts and their total votes
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS DownVotes
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
UserRanking AS (
    -- Assigning ranks based on post count and upvotes
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY PostCount DESC, UpVotes DESC) AS Rank
    FROM 
        MostActiveUsers
),
TagPostStats AS (
    -- CTE to get average views per tag including tags and related post statistics
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        AVG(P.ViewCount) AS AvgViews,
        AVG(COALESCE(P.CommentCount, 0)) AS AvgComments
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%<' || T.TagName || '>%' -- Simulated tag matching
    GROUP BY 
        T.TagName
),
PostHistoryStats AS (
    -- Get count of post history actions per type for posts created in the last year
    SELECT 
        PHT.PostHistoryTypeId,
        COUNT(PH.Id) AS ActionCount
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        PHT.PostHistoryTypeId
)
-- Final Query
SELECT 
    UR.DisplayName,
    UR.PostCount,
    UR.UpVotes,
    UR.DownVotes,
    T.TagName,
    T.AvgViews,
    T.AvgComments,
    PHS.PostHistoryTypeId,
    PHS.ActionCount
FROM 
    UserRanking UR
FULL OUTER JOIN 
    TagPostStats T ON UR.Rank <= 10 -- Top 10 active users with tags statistics
FULL OUTER JOIN 
    PostHistoryStats PHS ON UR.PostCount > 0 -- Only consider users with posts
WHERE 
    (UR.UpVotes > 50 OR UR.DownVotes = 0) -- Filter to only include users with high upvotes or no downvotes
ORDER BY 
    UR.Rank, T.AvgViews DESC NULLS LAST;

