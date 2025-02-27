WITH TagStatistics AS (
    SELECT 
        t.TagName, 
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
EngagementMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(c.CommentCount, 0) AS TotalComments,
        COALESCE(v.VoteCount, 0) AS TotalVotes,
        COALESCE(bc.BadgeCount, 0) AS UserBadgeCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN UserBadgeCounts bc ON p.OwnerUserId = bc.UserId
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.AvgUserReputation,
    em.PostId,
    em.Title,
    em.TotalComments,
    em.TotalVotes,
    em.UserBadgeCount
FROM 
    TagStatistics ts
JOIN 
    EngagementMetrics em ON ts.PostCount > 0
ORDER BY 
    ts.PostCount DESC, ts.AvgUserReputation DESC
LIMIT 10;
