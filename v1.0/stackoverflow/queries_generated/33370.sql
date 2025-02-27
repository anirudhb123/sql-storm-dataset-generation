WITH RecursivePostHierarchy AS (
    -- Recursive CTE to find all answers for questions, up to 5 levels deep
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Question posts only
    UNION ALL
    SELECT 
        a.Id,
        a.ParentId,
        a.Title,
        Level + 1
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostHierarchy r ON a.ParentId = r.PostId
    WHERE 
        a.PostTypeId = 2 -- Answer posts only
        AND Level < 5 -- Limit to 5 levels deep
),
PostWithVotes AS (
    -- CTE to aggregate vote counts for each post
    SELECT 
        p.Id,
        p.Title,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title
),
UserBadges AS (
    -- CTE to count badges for users, filtering only those with Gold badges
    SELECT 
        b.UserId,
        COUNT(b.Id) AS GoldBadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 -- Gold badges
    GROUP BY 
        b.UserId
),
TopUsers AS (
    -- CTE to get top users based on reputation and their gold badge count
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COALESCE(ub.GoldBadgeCount, 0) AS GoldBadgeCount
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        u.Reputation > 1000 -- Consider only users with reputation greater than 1000
)
-- Final query to get a list of questions with their answers and voted counts, along with the top users
SELECT 
    ph.PostId AS QuestionId,
    ph.Title AS QuestionTitle,
    pw.UpVotes,
    pw.DownVotes,
    tu.DisplayName AS TopUserName,
    tu.Reputation AS TopUserReputation,
    tu.GoldBadgeCount AS TopUserGoldBadgeCount,
    ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.Level) AS AnswerLevel
FROM 
    RecursivePostHierarchy ph
JOIN 
    PostWithVotes pw ON ph.PostId = pw.Id
JOIN 
    TopUsers tu ON pw.UpVotes > 5 -- Join only if there are more than 5 upvotes for the question
ORDER BY 
    ph.PostId, AnswerLevel;
