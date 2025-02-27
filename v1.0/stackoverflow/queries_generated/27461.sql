WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(coalesce(c.Score, 0)) AS CommentScore,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges,
        DATEDIFF('day', MIN(u.CreationDate), MAX(p.CreationDate)) AS DaysActive
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
), UserPerformance AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        ue.QuestionCount,
        ue.AnswerCount,
        ue.CommentScore,
        ue.TotalUpVotes,
        ue.TotalDownVotes,
        ue.GoldBadges,
        ue.SilverBadges,
        ue.BronzeBadges,
        ue.DaysActive,
        ROUND(ue.TotalUpVotes::numeric / NULLIF(ue.QuestionCount, 0), 2) AS UpVotePerQuestion,
        ROUND(ue.TotalDownVotes::numeric / NULLIF(ue.QuestionCount, 0), 2) AS DownVotePerQuestion,
        ROUND(ue.CommentScore::numeric / NULLIF(ue.AnswerCount, 0), 2) AS AvgCommentScorePerAnswer
    FROM 
        UserEngagement ue
    WHERE 
        ue.DaysActive >= 30  -- Only consider users active for at least 30 days
        AND ue.QuestionCount > 0  -- Must have asked at least one question
)

SELECT 
    up.DisplayName,
    up.QuestionCount,
    up.AnswerCount,
    up.CommentScore,
    up.TotalUpVotes,
    up.TotalDownVotes,
    up.GoldBadges,
    up.SilverBadges,
    up.BronzeBadges,
    up.UpVotePerQuestion,
    up.DownVotePerQuestion,
    up.AvgCommentScorePerAnswer,
    RANK() OVER (ORDER BY up.QuestionCount DESC, up.TotalUpVotes DESC) AS Rank
FROM 
    UserPerformance up
ORDER BY 
    Rank;

This SQL query provides a detailed benchmarking of user engagement and performance on a platform like Stack Overflow. It aggregates user activity, calculates various interactive metrics, and ranks users based on question counts and total upvotes. The use of Common Table Expressions (CTEs) allows for a structured and readable approach to deriving insights from the data. The final result set will highlight the most active users while evaluating their contributions to the community.
