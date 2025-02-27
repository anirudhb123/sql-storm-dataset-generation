WITH CTE_PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        COALESCE(p.ViewCount, 0) AS ViewCount,
        COALESCE(a.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COALESCE(b.UserId, -1) AS LastEditorId,
        b.LastEditDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.AcceptedAnswerId  -- correlates if it is a question
    LEFT JOIN 
        (SELECT DISTINCT ON (LastEditorUserId) LastEditorUserId, LastEditDate 
         FROM Posts 
         ORDER BY LastEditorUserId, LastEditDate DESC) b ON p.LastEditorUserId = b.LastEditorUserId
    WHERE 
        p.Score > 5 AND                                               -- Filter criteria 
        p.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 year'      -- Recent year posts
),
CTE_UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
CTE_Badges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeList,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
FinalResult AS (
    SELECT 
        p.PostId,
        p.Title,
        p.ViewCount,
        p.LastActivityDate,
        u.DisplayName AS OwnerDisplayName,
        u.AvgReputation,
        ba.BadgeList,
        b.BadgeCount,
        p.UserPostRank
    FROM 
        CTE_PostDetails p
    LEFT JOIN 
        CTE_UserActivity u ON p.OwnerUserId = u.UserId
    LEFT JOIN 
        CTE_Badges ba ON u.UserId = ba.UserId
    WHERE 
        COALESCE(p.AcceptedAnswerId, -1) <> -1                     -- Only accepted questions
        OR (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.PostId) > 5 -- more than 5 comments
    ORDER BY 
        p.LastActivityDate DESC
)
SELECT 
    *
FROM 
    FinalResult
WHERE 
    OwnerDisplayName IS NOT NULL 
    AND UserPostRank <= 5  -- Top 5 for each user
ORDER BY 
    COALESCE(AvgReputation, 0) DESC, ViewCount DESC;

In this SQL query:
- The query utilizes CTEs to break down logic into manageable parts: 
  - `CTE_PostDetails` collects details about posts along with ranks.
  - `CTE_UserActivity` aggregates user activity metrics.
  - `CTE_Badges` gathers badge information for users.
- An outer join is employed to correlate post and user data.
- Complicated predicates filter posts based on acceptance and comments.
- Window functions rank user posts.
- `STRING_AGG` is used to concatenate badge names into a single string. 
- The final selection filters to ensure the output shows only high-ranked posts.
