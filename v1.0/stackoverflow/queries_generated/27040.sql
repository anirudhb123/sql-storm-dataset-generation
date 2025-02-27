WITH TagArray AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
), UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
        SUM(COALESCE(p.AnswerCount, 0)) AS TotalAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), TagStatistics AS (
    SELECT 
        ta.TagName,
        COUNT(DISTINCT ta.PostId) AS PostCount,
        COUNT(DISTINCT u.UserId) AS UserCount,
        SUM(ua.UpVoteCount) AS TotalUpVotes,
        SUM(ua.DownVoteCount) AS TotalDownVotes,
        SUM(ua.QuestionCount) AS TotalQuestions,
        SUM(ua.TotalAnswers) AS TotalAnswers
    FROM 
        TagArray ta
    JOIN 
        UserActivity ua ON ua.QuestionCount > 0 -- Only users with questions
    GROUP BY 
        ta.TagName
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.UserCount,
    ts.TotalUpVotes,
    ts.TotalDownVotes,
    ts.TotalQuestions,
    ts.TotalAnswers,
    (ts.TotalUpVotes - ts.TotalDownVotes) AS NetVotes,
    (CASE 
        WHEN ts.PostCount > 0 THEN (ts.TotalUpVotes::decimal / ts.PostCount) 
        ELSE 0 
    END) AS UpvotePerPost,
    (CASE 
        WHEN ts.UserCount > 0 THEN (ts.TotalQuestions::decimal / ts.UserCount) 
        ELSE 0 
    END) AS AvgQuestionsPerUser
FROM 
    TagStatistics ts
ORDER BY 
    ts.PostCount DESC, ts.NetVotes DESC
LIMIT 10;
