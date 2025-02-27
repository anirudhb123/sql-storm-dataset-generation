WITH RecursiveTagCounts AS (
    -- CTE to recursively count the usage of tags in posts
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%' )  -- Uses string matching to identify tags in posts
    GROUP BY 
        t.Id, t.TagName

    UNION ALL

    SELECT 
        t.Id,
        t.TagName,
        COUNT(p.Id) + r.PostCount 
    FROM 
        Tags t
    JOIN 
        RecursiveTagCounts r ON t.Id = r.TagId
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%' )
    GROUP BY 
        t.Id, t.TagName, r.PostCount
),
-- Aggregate posts and their votes to calculate overall scores
PostVotes AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) - COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Score
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        p.Id, p.Title
),
-- CTE to calculate user reputations and their badge counts
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
-- Final selection combining all CTEs
SELECT 
    ut.UserId,
    ut.DisplayName,
    ut.Reputation,
    ut.BadgeCount,
    pt.PostId,
    pt.Title AS PostTitle,
    pt.UpVotes,
    pt.DownVotes,
    pt.Score,
    rt.PostCount AS TagCount
FROM 
    UserReputation ut
JOIN 
    PostVotes pt ON ut.UserId = pt.PostId -- Assuming users can be matched to posts by their contributions
LEFT JOIN 
    RecursiveTagCounts rt ON rt.TagId = ANY(string_to_array(pt.Title, ' '))  -- Assuming tags are part of the title for demonstration
WHERE 
    ut.Reputation > 1000  -- Filter out low-reputation users
ORDER BY 
    ut.Reputation DESC, pt.Score DESC;  -- Ordering by reputation and post score for ranking
