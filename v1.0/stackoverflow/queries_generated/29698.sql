WITH TagStats AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN Posts.Score > 0 THEN 1 ELSE 0 END) AS FeaturedCount
    FROM 
        Tags 
    LEFT JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '>')::int[])
    GROUP BY 
        Tags.TagName
),
UserActivity AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS TotalPosts,
        COUNT(DISTINCT Comments.Id) AS TotalComments,
        SUM(Votes.VoteTypeId = 2) AS UpVotes,
        SUM(Votes.VoteTypeId = 3) AS DownVotes
    FROM 
        Users 
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Comments ON Users.Id = Comments.UserId
    LEFT JOIN 
        Votes ON Users.Id = Votes.UserId
    GROUP BY 
        Users.Id, Users.DisplayName
),
CloseReasons AS (
    SELECT 
        CloseReasonTypes.Name AS ReasonName,
        COUNT(PostHistory.Id) AS CloseCount
    FROM 
        PostHistory
    JOIN 
        CloseReasonTypes ON PostHistory.Comment = CloseReasonTypes.Id::text
    WHERE 
        PostHistory.PostHistoryTypeId = 10 -- Close reasons
    GROUP BY 
        CloseReasonTypes.Name
)
SELECT 
    t.TagName,
    t.PostCount,
    t.QuestionCount,
    t.AnswerCount,
    t.FeaturedCount,
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.TotalComments,
    u.UpVotes,
    u.DownVotes,
    cr.ReasonName,
    cr.CloseCount
FROM 
    TagStats t
JOIN 
    UserActivity u ON u.TotalPosts > 0
LEFT JOIN 
    CloseReasons cr ON cr.CloseCount > 0
ORDER BY 
    t.PostCount DESC, u.TotalPosts DESC, cr.CloseCount DESC;
