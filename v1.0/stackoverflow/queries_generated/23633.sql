WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        MAX(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS HasDownVote
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
RecentBadges AS (
    SELECT 
        b.UserId,
        b.Name AS BadgeName,
        ROW_NUMBER() OVER (PARTITION BY b.UserId ORDER BY b.Date DESC) AS BadgeRank
    FROM 
        Badges b
    WHERE 
        b.Date >= NOW() - INTERVAL '1 year'
)
SELECT 
    up.DisplayName,
    up.Reputation,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.CommentCount,
    rp.UpVoteCount,
    CASE 
        WHEN rp.HasDownVote = 1 THEN 'Yes'
        ELSE 'No'
    END AS HasDownVote,
    rb.BadgeName
FROM 
    Users up
LEFT JOIN 
    RankedPosts rp ON up.Id = rp.OwnerUserId AND rp.OwnerPostRank = 1
LEFT JOIN 
    RecentBadges rb ON up.Id = rb.UserId AND rb.BadgeRank = 1
WHERE 
    up.Reputation > (
        SELECT AVG(Reputation) FROM Users
    ) AND 
    (up.Location IS NOT NULL AND up.Location LIKE '%USA%')
ORDER BY 
    up.Reputation DESC,
    rp.UpVoteCount DESC
LIMIT 10;

This SQL query constructs a performance benchmark involving several complex components:
- Common Table Expressions (CTEs) to encapsulate the logic for gathering ranked posts and recent badges.
- A combination of outer joins and correlated subqueries to retrieve user details alongside their top-ranked posts and the most recent badge earned.
- Window functions to rank posts by their creation date and badges by their earning date.
- Complex expressions that handle demographic filtering (users from the USA with above-average reputation) combined with various aggregate functions (counting comments and summing up-votes).
- NULL checks and simple CASE expressions to incorporate binary logic (whether a user has downvoted). 

This query provides a rich interaction of SQL constructs designed to extract meaningful insights while pushing the boundaries of conventional querying practices.
