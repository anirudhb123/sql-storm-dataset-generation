WITH TagStats AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(COALESCE(Posts.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(Posts.Score, 0)) AS TotalScore
    FROM 
        Tags
    LEFT JOIN 
        Posts ON Tags.Id = ANY(string_to_array(Posts.Tags, '><')::int[]) 
    GROUP BY 
        Tags.TagName
), 
UserActivity AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS QuestionCount,
        COUNT(DISTINCT Comments.Id) AS CommentCount,
        SUM(Votes.VoteTypeId = 2) AS UpVoteCount,
        SUM(Votes.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId AND Posts.PostTypeId = 1
    LEFT JOIN 
        Comments ON Users.Id = Comments.UserId
    LEFT JOIN 
        Votes ON Users.Id = Votes.UserId
    GROUP BY 
        Users.Id, Users.DisplayName
), 
PostHistoryStats AS (
    SELECT 
        PH.PostId,
        STRING_AGG(DISTINCT PHT.Name, ', ') AS HistoryTypes,
        COUNT(PH.Id) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
)
SELECT 
    ts.TagName,
    ts.PostCount AS TotalPosts,
    ts.TotalViews,
    ts.TotalScore,
    ua.UserId,
    ua.DisplayName,
    ua.QuestionCount AS UserQuestions,
    ua.CommentCount AS UserComments,
    ua.UpVoteCount AS UserUpVotes,
    ua.DownVoteCount AS UserDownVotes,
    phs.HistoryTypes,
    phs.EditCount AS TotalEdits,
    phs.LastEditDate
FROM 
    TagStats ts
JOIN 
    UserActivity ua ON ua.QuestionCount > 0
LEFT JOIN 
    PostHistoryStats phs ON ts.PostCount > 0
ORDER BY 
    ts.TotalViews DESC, ua.UpVoteCount DESC
LIMIT 100;
