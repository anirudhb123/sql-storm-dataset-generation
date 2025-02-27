WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId IN (10, 11, 12) THEN 1 ELSE 0 END) AS ClosedPosts,
        ROW_NUMBER() OVER (ORDER BY COUNT(p.Id) DESC) AS PostRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
), 

ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ActionCount,
        MAX(ph.CreationDate) AS LastActionDate,
        STRING_AGG(DISTINCT ph.UserDisplayName, ', ') AS Modifiers
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) -- Closed, Reopened, Deleted
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
), 

MostActiveUsers AS (
    SELECT 
        UserId,
        COUNT(*) AS VoteCount,
        COUNT(DISTINCT PostId) AS VotedPosts,
        SUM(CASE WHEN VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS Influence
    FROM 
        Votes v
    GROUP BY 
        UserId
    HAVING 
        COUNT(*) > 50
), 

TagStats AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostsWithTag,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Votes v ON v.PostId = p.Id AND v.VoteTypeId IN (8, 9) -- Bounty Start, Bounty Close
    GROUP BY 
        t.Id, t.TagName
), 

UserImpact AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.QuestionCount,
        ups.AnswerCount,
        ups.ClosedPosts,
        mu.VoteCount,
        mu.VotedPosts,
        mu.Influence,
        ts.PostsWithTag AS TagsUsed,
        ts.TotalBounty
    FROM 
        UserPostStats ups
    JOIN 
        MostActiveUsers mu ON ups.UserId = mu.UserId
    LEFT JOIN 
        TagStats ts ON ups.UserId = ts.TagId
    WHERE 
        ups.TotalPosts > 10 AND mu.Influence > 20
)

SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    COALESCE(u.QuestionCount, 0) AS Questions,
    COALESCE(u.AnswerCount, 0) AS Answers,
    COALESCE(u.ClosedPosts, 0) AS Closed,
    COALESCE(u.VoteCount, 0) AS TotalVotes,
    COALESCE(u.VotedPosts, 0) AS UniqueVotedPosts,
    COALESCE(u.Influence, 0) AS VoteInfluence,
    COALESCE(u.TagsUsed, 0) AS TagsUtilized,
    COALESCE(u.TotalBounty, 0) AS TotalBountyEarned
FROM 
    UserImpact u
ORDER BY 
    u.TotalPosts DESC, u.VoteInfluence DESC
LIMIT 50;

-- This query aggregates performance data based on post activity, including user statistics, their impact through votes,
-- and tags they have engaged with while handling various SQL constructs such as CTEs, window functions, and outer joins.
