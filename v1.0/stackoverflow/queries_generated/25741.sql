WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(u.Reputation) AS AvgUserReputation,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS UserNames
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        p.CreationDate,
        t.TagName
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        p.Id, t.TagName
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        STRING_AGG(DISTINCT t.TagName, ', ') AS AchievedTags
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        u.Id
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.AvgUserReputation,
    ts.UserNames,
    COUNT(DISTINCT ea.PostId) AS ActivePostCount,
    SUM(ea.UpVoteCount) AS TotalUpVotes,
    SUM(ea.DownVoteCount) AS TotalDownVotes,
    STRING_AGG(DISTINCT ua.UserId || ' (' || ua.BadgeCount || ' Badges)', '; ') AS UserStatistics
FROM 
    TagStatistics ts
LEFT JOIN 
    PostEngagement ea ON ts.TagName = ea.TagName
LEFT JOIN 
    UserActivity ua ON ua.AchievedTags LIKE '%' || ts.TagName || '%'
GROUP BY 
    ts.TagName, ts.PostCount, ts.QuestionCount, ts.AnswerCount, ts.AvgUserReputation, ts.UserNames
ORDER BY 
    ts.PostCount DESC;
