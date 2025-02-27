WITH RecursivePostHierarchy AS (
    -- Recursive CTE to find the hierarchy of questions and their answers
    SELECT 
        p.Id AS PostId, 
        p.Title AS QuestionTitle, 
        p.OwnerUserId AS QuestionOwnerId, 
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions
    UNION ALL
    SELECT 
        a.Id AS PostId, 
        q.Title AS QuestionTitle, 
        a.OwnerUserId AS AnswerOwnerId, 
        rh.Level + 1 AS Level
    FROM 
        Posts a
    JOIN 
        RecursivePostHierarchy rh ON a.ParentId = rh.PostId -- Answers to questions
    WHERE 
        a.PostTypeId = 2 -- Answers
),
UserEngagement AS (
    -- CTE to analyze user engagement with posts
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.VoteTypeId = 2) AS Upvotes, -- Summing upvotes
        SUM(v.VoteTypeId = 3) AS Downvotes -- Summing downvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
BadgeSummary AS (
    -- CTE to summarize badges earned by users
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges, 
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges, 
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
UserPerformance AS (
    -- Aggregating user performance with window functions
    SELECT 
        ue.UserId,
        ue.DisplayName,
        ue.TotalPosts,
        ue.TotalComments,
        ue.Upvotes,
        ue.Downvotes,
        COALESCE(bs.GoldBadges, 0) AS GoldBadges,
        COALESCE(bs.SilverBadges, 0) AS SilverBadges,
        COALESCE(bs.BronzeBadges, 0) AS BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY ue.Upvotes DESC) AS UpvoteRank,
        ROW_NUMBER() OVER (ORDER BY ue.TotalPosts DESC) AS PostRank
    FROM 
        UserEngagement ue
    LEFT JOIN 
        BadgeSummary bs ON ue.UserId = bs.UserId
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.TotalPosts,
    up.TotalComments,
    up.Upvotes,
    up.Downvotes,
    up.GoldBadges,
    up.SilverBadges,
    up.BronzeBadges,
    up.UpvoteRank,
    up.PostRank,
    COUNT(DISTINCT r.PostId) AS NumberOfAnsweredQuestions 
FROM 
    UserPerformance up
LEFT JOIN 
    RecursivePostHierarchy r ON up.UserId = r.QuestionOwnerId OR up.UserId = r.AnswerOwnerId
GROUP BY 
    up.UserId, up.DisplayName, up.TotalPosts, up.TotalComments, up.Upvotes, 
    up.Downvotes, up.GoldBadges, up.SilverBadges, up.BronzeBadges, 
    up.UpvoteRank, up.PostRank
ORDER BY 
    up.Upvotes DESC, up.TotalPosts DESC;
