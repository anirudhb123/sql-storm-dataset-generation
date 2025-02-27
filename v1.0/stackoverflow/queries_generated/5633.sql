WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS TotalComments,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS TotalUpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS TotalDownVotes,
        COALESCE(SUM(v.VoteTypeId = 1), 0) AS AcceptedVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        p.Id, p.Title
),
EngagementSummary AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        pm.TotalComments,
        pm.TotalUpVotes,
        pm.TotalDownVotes,
        pm.AcceptedVotes,
        ue.QuestionCount,
        ue.AnswerCount,
        ue.GoldBadges,
        ue.SilverBadges,
        ue.BronzeBadges
    FROM 
        UserEngagement ue
    JOIN 
        PostMetrics pm ON ue.UserId = pm.PostId -- Assuming we want to join based on metrics related to user's posts
)
SELECT 
    UserId,
    DisplayName,
    QuestionCount,
    AnswerCount,
    TotalComments,
    TotalUpVotes,
    TotalDownVotes,
    AcceptedVotes,
    GoldBadges,
    SilverBadges,
    BronzeBadges
FROM 
    EngagementSummary
ORDER BY 
    TotalUpVotes DESC, TotalComments DESC, UserId;
