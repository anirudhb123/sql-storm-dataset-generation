WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        STRING_AGG(t.TagName, ', ') AS TagsList
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        UNNEST(string_to_array(p.Tags, ',')) AS t(TagName) ON TRUE
    GROUP BY 
        p.Id, p.Title, p.Score, p.PostTypeId
), 

RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        pht.Name AS ActionType,
        COUNT(ph.Id) AS ActionCount,
        MAX(ph.CreationDate) AS LastActionDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '90 days'
    GROUP BY 
        ph.PostId, pht.Name
),

FilteredUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000 AND 
        u.LastAccessDate >= NOW() - INTERVAL '1 year'
)

SELECT 
    r.PostId,
    r.Title,
    r.Score AS PostScore,
    r.CommentCount,
    r.ScoreRank,
    r.TagsList,
    COALESCE(rh.ActionCount, 0) AS RecentActionCount,
    rh.ActionType AS RecentActionType,
    u.DisplayName AS UserName,
    u.Reputation AS UserReputation,
    CASE 
        WHEN u.BadgeCount > 10 THEN 'Veteran'
        WHEN u.BadgeCount BETWEEN 5 AND 10 THEN 'Experienced'
        ELSE 'Newbie'
    END AS UserStatus
FROM 
    RankedPosts r
LEFT JOIN 
    RecentPostHistory rh ON r.PostId = rh.PostId
LEFT JOIN 
    Posts p ON r.PostId = p.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    r.CommentCount > 0 AND 
    (rh.LastActionDate IS NULL OR rh.LastActionDate >= NOW() - INTERVAL '30 days')
ORDER BY 
    r.Score DESC, r.CommentCount DESC, UserReputation DESC;

This SQL query spans multiple advanced constructs, including:
1. Common Table Expressions (CTEs) for organizing code and enhancing readability.
2. Window functions to calculate ranks based on score and partitioning by post type.
3. Advanced filtering on user reputation and recent activity, including NULL logic with COALESCE.
4. String aggregation to compile a list of tags per post.
5. Correlated subqueries to gather user badges count and categorize users based on their activity.
6. Complex predicates combining various filters to effectively drill down into relevant posts and their authors.

The query is designed for performance benchmarking by employing various SQL functionalities to assess execution time and resource consumption under different scenarios, thus making it elaborate and interesting.
