WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(COUNT(DISTINCT p.Id), 0) AS PostCount,
        COALESCE(COUNT(DISTINCT c.Id), 0) AS CommentCount,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT crt.Name, ', ') FILTER (WHERE ph.PostHistoryTypeId = 10) AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON ph.Comment::int = crt.Id
    GROUP BY 
        ph.PostId
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(c.CloseReasons, 'No close reasons') AS CloseReasons,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS PopularityRank
    FROM 
        Posts p
    LEFT JOIN 
        CloseReasons c ON p.Id = c.PostId
    WHERE 
        p.Score IS NOT NULL
        AND p.ViewCount > 10
        AND p.CreationDate >= NOW() - INTERVAL '1 month'
),
TopUsersWithPopularPosts AS (
    SELECT 
        us.DisplayName,
        us.Reputation,
        pp.PostId,
        pp.Title,
        pp.CreationDate,
        pp.Score,
        pp.ViewCount,
        pp.CloseReasons
    FROM 
        UserStats us
    JOIN 
        Posts p ON us.UserId = p.OwnerUserId
    JOIN 
        PopularPosts pp ON p.Id = pp.PostId
    WHERE 
        us.UserRank <= 10
)

SELECT 
    t.DisplayName,
    t.Reputation,
    t.PostId,
    t.Title,
    t.CreationDate,
    t.Score,
    t.ViewCount,
    t.CloseReasons
FROM 
    TopUsersWithPopularPosts t
WHERE 
    EXISTS (SELECT 1 
            FROM Votes v 
            WHERE v.PostId = t.PostId 
              AND v.UserId = t.UserId 
              AND v.VoteTypeId = 2) 
OR 
    NOT EXISTS (SELECT 1 
                FROM Votes v 
                WHERE v.PostId = t.PostId 
                  AND v.UserId = t.UserId)
ORDER BY 
    t.Reputation DESC, 
    t.Score DESC;

This SQL query incorporates several advanced constructs:
- Common Table Expressions (CTEs) are used to prepare data in stages, allowing for modular construction of the data query.
- Window functions like `RANK()` and `ROW_NUMBER()` are used to rank users and determine the popularity of posts based on multiple criteria.
- An outer join is used to aggregate data from various tables while preserving all users, regardless of whether they have posts.
- Conditional aggregation and string functions facilitate the creation of lists from historical data, handling NULLs appropriately.
- The final selection applies a combination of EXISTS and NOT EXISTS to filter results based on user interactions with posts, emphasizing nuanced logic to capture specific conditions regarding voting behavior.
- The query leverages rankings and views to prioritize users and their contributions, showing a blend of both statistics and semantic meaning within the user contributions.
