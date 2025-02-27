WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS ViewRank,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) -- Upvotes and Downvotes
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.ViewCount
), UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        SUM(b.Class) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
), BadPostHistory AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEdited,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 10) -- Edited Title, Body, Tags, Post Closed
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Id,
    p.Title,
    p.CreationDate,
    ur.UserId,
    ur.Reputation,
    ur.TotalBadges,
    r.ViewRank,
    r.ViewCount,
    COALESCE(bph.EditCount, 0) AS EditCount,
    COALESCE(bph.LastEdited, 'No Edits') AS LastEdited,
    COALESCE(bph.HistoryTypes, 'No History') AS HistoryTypes
FROM 
    RankedPosts r
JOIN 
    Posts p ON r.PostId = p.Id
JOIN 
    UserReputation ur ON p.OwnerUserId = ur.UserId
LEFT JOIN 
    BadPostHistory bph ON p.Id = bph.PostId
WHERE 
    r.ViewRank <= 5 -- Top 5 posts by view count per user
ORDER BY 
    ur.Reputation DESC, r.ViewCount DESC
LIMIT 20;

### Explanation:
1. **CTEs**:
   - `RankedPosts`: This calculates a view rank for each post within the last year based on view counts and also counts total votes.
   - `UserReputation`: This gathers the total reputation and number of badges for each user.
   - `BadPostHistory`: This collects edit history for a set of relevant post history types, counting edits and aggregating types.

2. **Joins**:
   - It joins the ranked post data with `Posts`, `UserReputation`, and `BadPostHistory` to gather comprehensive details.

3. **Filtering and Ordering**:
   - The main query filters posts to those in the top 5 viewed for each user and orders results by user reputation and post view counts for sorting.

4. **Aggregation & NULL Handling**:
   - Uses `COALESCE` to handle NULL values for posts with no edits or existing history, and provides sensible defaults.

5. **Complexity**:
   - Incorporated various SQL features such as window functions for ranking, and aggregate functions to gather additional user and post history data.
