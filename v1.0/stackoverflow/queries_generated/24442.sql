WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(DISTINCT c.Id) OVER (PARTITION BY p.OwnerUserId) AS CommentCount,
        COUNT(DISTINCT v.Id) OVER (PARTITION BY p.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '60 days'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(b.Class, 0) AS BadgeClass
    FROM 
        Users u
    LEFT JOIN 
        (SELECT UserId, MAX(Class) AS Class FROM Badges GROUP BY UserId) b ON u.Id = b.UserId
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        PH.CreationDate AS ClosedDate,
        COUNT(DISTINCT PH.Id) AS HistoryCount
    FROM 
        Posts p
    JOIN 
        PostHistory PH ON p.Id = PH.PostId 
    WHERE 
        PH.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        p.Id, PH.CreationDate
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    rp.VoteCount,
    u.Reputation,
    u.BadgeClass,
    COALESCE(cp.ClosedDate, 'No Closure') AS ClosedDate,
    cp.HistoryCount,
    CASE 
        WHEN rp.Score > 100 THEN 'High Scorer'
        ELSE 'Regular Post'
    END AS PostCategory,
    (SELECT STRING_AGG(DISTINCT t.TagName, ', ')
     FROM Tags t 
     WHERE t.Id IN (SELECT UNNEST(string_to_array(substring(rp.Body, position('<tags>' IN rp.Body) + 6, 
                      position('</tags>' IN rp.Body) - (position('<tags>' IN rp.Body) + 6)), ','))::int[])) 
     ORDER BY t.TagName) AS Tags
FROM 
    RecentPosts rp
JOIN 
    UserReputation u ON rp.OwnerUserId = u.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    COALESCE(u.BadgeClass, 0) = 1
    AND rp.CommentCount > 5
    AND (rp.Score / NULLIF(rp.ViewCount, 0)) > 0.1
ORDER BY 
    rp.CreationDate DESC
LIMIT 100;

This SQL query includes:
- CTEs to filter recent posts, calculate user reputation with badge classes, and identify closed posts.
- Uses window functions for ranking within recent posts and counting comments and votes.
- Incorporates a conditional logic using a CASE statement to categorize posts based on their scores.
- Utilizes STRING_AGG and array functions to gather tags associated with each post dynamically.
- Involves outer joins and NULL logic to ensure all types of data are captured efficiently.
- Implements complex filtering conditions to derive meaningful insights from the dataset.
