WITH TagStats AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Posts.ViewCount) AS TotalViews,
        SUM(Posts.Score) AS TotalScore
    FROM 
        Tags
    JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '><')::int[])
    GROUP BY 
        Tags.TagName
),
UserStats AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS PostsCreated,
        SUM(COALESCE(Posts.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(Votes.VoteTypeId = 2, 0)::int) AS UpVotesReceived,
        SUM(COALESCE(Votes.VoteTypeId = 3, 0)::int) AS DownVotesReceived
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Users.Id
),
PostHistoryCounts AS (
    SELECT 
        PostId,
        MAX(CASE WHEN PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        MAX(CASE WHEN PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenCount
    FROM 
        PostHistory
    GROUP BY 
        PostId
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.PostsCreated,
    U.TotalViews,
    U.UpVotesReceived,
    U.DownVotesReceived,
    T.TagName,
    T.PostCount,
    T.TotalViews AS TagTotalViews,
    T.TotalScore AS TagTotalScore,
    PH.CloseCount,
    PH.ReopenCount
FROM 
    UserStats U
JOIN 
    TagStats T ON U.PostsCreated > 0
JOIN 
    PostHistoryCounts PH ON U.PostsCreated > PH.CloseCount + PH.ReopenCount
ORDER BY 
    U.TotalViews DESC,
    T.TotalViews DESC;
