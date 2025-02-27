WITH RecursivePostCTE AS (
    -- Recursive CTE to fetch all answers and their corresponding questions
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        rp.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE rp ON p.ParentId = rp.PostId
    WHERE
        p.PostTypeId = 2 -- Answers
),
VoteInfo AS (
    -- Subquery to fetch user vote counts for both questions and answers
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVoteCount
    FROM 
        Votes
    GROUP BY 
        PostId
),
UserBadgeCounts AS (
    -- Aggregating badge counts per user
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
PostScoreWithUserInfo AS (
    -- Join to fetch scores with user reputation and number of badges
    SELECT 
        rp.PostId,
        rp.Title,
        u.Reputation,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        v.UpVoteCount,
        v.DownVoteCount,
        rp.Level
    FROM 
        RecursivePostCTE rp
    INNER JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        UserBadgeCounts ub ON ub.UserId = u.Id
    LEFT JOIN 
        VoteInfo v ON v.PostId = rp.PostId
)
SELECT 
    p.PostId,
    p.Title,
    p.Reputation,
    (p.UpVoteCount - p.DownVoteCount) AS NetVotes,
    p.GoldBadges,
    p.SilverBadges,
    p.BronzeBadges,
    p.Level
FROM 
    PostScoreWithUserInfo p
WHERE 
    p.Level = 0 -- Only show top-level questions
ORDER BY 
    NetVotes DESC,
    p.Reputation DESC
LIMIT 10; -- Limit results to top 10 questions by net votes
