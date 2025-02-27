WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= current_date - interval '1 year'
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Date >= current_date - interval '1 year'
    GROUP BY 
        b.UserId
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 10, 11, 12)  -- Relevant edits or state changes
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(b.BadgeCount, 0) AS TotalBadges,
    COALESCE(b.BadgeNames, 'None') AS BadgeNames,
    r.PostId,
    r.Title,
    r.Score,
    r.CreationDate,
    p.HistoryCount,
    p.LastEditDate
FROM 
    Users u
LEFT JOIN 
    UserBadges b ON u.Id = b.UserId
LEFT JOIN 
    RankedPosts r ON u.Id = r.OwnerUserId AND r.UserRank = 1  -- Get the top-ranked post for each user
LEFT JOIN 
    PostHistoryAggregates p ON r.PostId = p.PostId
WHERE 
    u.Reputation > 100 AND  -- Only consider users with reputation > 100
    u.CreationDate < (current_date - interval '1 year')  -- Users must be active for more than 1 year
ORDER BY 
    u.Reputation DESC, r.Score DESC
LIMIT 100  -- Limit results to top 100 users
OFFSET 0;  -- Pagination - can be modified for different pages

This query does the following:
1. **CTEs** for ranking posts, aggregating badges by user, and counting post history entries to set a context for the users.
2. Uses the **ROW_NUMBER** window function to rank posts by score for each user, focusing on the past year.
3. Joins user info with aggregated badge counts while handling cases of users having no badges using **COALESCE**.
4. Filters users based on reputation and activity, emphasizing engagement.
5. Orders results by reputation and the score of their top post.
6. Implement pagination with a limit and offset. 

This query incorporates many advanced SQL features while navigating some corner cases, such as handling missing badges and filtering based on user activity.
