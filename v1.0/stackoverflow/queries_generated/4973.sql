WITH UserVotes AS (
    SELECT 
        v.UserId, 
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes, 
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM 
        Votes v
    GROUP BY 
        v.UserId
), 
PostDetails AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.ViewCount, 
        p.CreationDate, 
        COALESCE(ph.Comment, '') AS LastEditComment,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 4 -- Edit Title
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
), 
RankedPosts AS (
    SELECT 
        pd.*, 
        ROW_NUMBER() OVER (ORDER BY pd.ViewCount DESC, pd.CreationDate ASC) AS PopularityRank
    FROM 
        PostDetails pd
    WHERE 
        pd.rn = 1
)

SELECT 
    u.DisplayName, 
    u.Reputation,
    p.Title,
    p.ViewCount,
    p.CreationDate,
    p.LastEditComment,
    COALESCE(v.Upvotes, 0) AS TotalUpvotes,
    COALESCE(v.Downvotes, 0) AS TotalDownvotes
FROM 
    Users u
INNER JOIN 
    RankedPosts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    UserVotes v ON u.Id = v.UserId
WHERE 
    u.Reputation > (SELECT AVG(Reputation) FROM Users) -- Users above average reputation
    AND p.PopularityRank <= 10 -- Top 10 most viewed posts
ORDER BY 
    u.Reputation DESC, 
    p.ViewCount DESC;
