WITH RecursivePostHierarchy AS (
    -- Recursive CTE to gather all parent posts for each answer
    SELECT 
        p.Id AS PostId, 
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 2  -- Starting with answers (PostTypeId = 2)

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.Id = rph.ParentId
),
PostDetails AS (
    -- CTE to gather post details including answers, users, and their badges
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM RecursivePostHierarchy rph WHERE rph.ParentId = p.Id) AS AnswerCount,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Focusing on questions (PostTypeId = 1)
    GROUP BY 
        p.Id, u.DisplayName, u.Reputation
),
VoteStatistics AS (
    -- CTE to calculate vote statistics for each post
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostRanking AS (
    -- CTE to rank posts based on score and views
    SELECT 
        pd.*, 
        vs.UpVotes, 
        vs.DownVotes,
        RANK() OVER (ORDER BY pd.Score DESC, pd.ViewCount DESC) AS Rank
    FROM 
        PostDetails pd
    LEFT JOIN 
        VoteStatistics vs ON pd.PostId = vs.PostId
)
-- Final selection showing all the gathered data with ranking
SELECT 
    pr.*, 
    CONCAT(pr.OwnerDisplayName, ' (Reputation: ', pr.OwnerReputation, ')') AS OwnerInfo,
    CONCAT('Gold: ', pr.GoldBadges, ', Silver: ', pr.SilverBadges, ', Bronze: ', pr.BronzeBadges) AS BadgeCount,
    (SELECT STRING_AGG(T.TagName, ', ') FROM Tags T WHERE T.Id IN (SELECT unnest(string_to_array(SUBSTRING(pd.Tags FROM '^\{(.+?)\}$'), ','))::int)) AS Tags
FROM 
    PostRanking pr
WHERE 
    pr.Rank <= 10  -- Limit to top 10 posts
ORDER BY 
    pr.Rank;
