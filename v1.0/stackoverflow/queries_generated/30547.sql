WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with Questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        Posts parent ON p.ParentId = parent.Id
    INNER JOIN 
        RecursiveCTE r ON parent.Id = r.PostId
)

SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS PostCount,
    SUM(COALESCE(v.BountyAmount, 0)) AS TotalBountyAmount,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    MAX(vote_count.VoteCount) AS MaxVoteCount,
    AVG(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptanceRate,
    ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY SUM(p.Score) DESC) AS Rank
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)  -- Counting upvotes and downvotes
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    Tags t ON t.Id IN (SELECT UNNEST(string_to_array(p.Tags, '><'))::int)
LEFT JOIN 
    (SELECT 
        PostId, 
        COUNT(*) AS VoteCount 
     FROM 
        Votes 
     GROUP BY 
        PostId) vote_count ON vote_count.PostId = p.Id
GROUP BY 
    u.Id
HAVING 
    COUNT(DISTINCT p.Id) > 10  -- More than 10 posts
ORDER BY 
    TotalBountyAmount DESC,
    Rank
OPTION (RECOMPILE);

This SQL query is designed to analyze user contributions on a StackOverflow-like platform, combining various constructs like recursive CTEs, aggregation functions, string manipulation, and window functions. It counts user posts, sums their bounty amounts, categorizes associated tags, and assesses their overall reputation, providing a ranking for users based on post scores and total contributions.
