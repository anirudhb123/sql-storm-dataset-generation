WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY CASE WHEN u.Reputation >= 1000 THEN 'High Reputation' 
                                              WHEN u.Reputation >= 500 THEN 'Medium Reputation' 
                                              ELSE 'Low Reputation' END 
                           ORDER BY u.Reputation DESC) AS Rank
    FROM Users u
    WHERE u.Reputation IS NOT NULL
), 
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title, 
        COUNT(c.Id) AS CommentCount, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        MAX(p.CreationDate) AS MostRecentActivity,
        COUNT(DISTINCT ph.Id) AS EditCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.CreationDate >= p.CreationDate
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId AND ph.CreationDate >= p.CreationDate
    GROUP BY p.Id
),
FilteredPosts AS (
    SELECT 
        ps.PostId, 
        ps.Title, 
        ps.CommentCount, 
        ps.UpvoteCount, 
        ps.DownvoteCount, 
        RANK() OVER (ORDER BY ps.CommentCount DESC, ps.UpvoteCount DESC) AS PostRank
    FROM PostStats ps
    WHERE ps.CommentCount > 5 AND ps.UpvoteCount - ps.DownvoteCount > 10
),
UserPostInteraction AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        fp.PostId,
        fp.Title,
        CASE 
            WHEN fp.PostRank <= 10 THEN 'Top Posts'
            WHEN fp.PostRank <= 50 THEN 'Medium Posts'
            ELSE 'Low Engagement Posts'
        END AS EngagementLevel
    FROM RankedUsers u
    JOIN FilteredPosts fp ON u.Reputation >= 1000 -- Considering only high reputation users
)
SELECT 
    upi.UserId,
    upi.DisplayName,
    upi.PostId,
    upi.Title,
    upi.EngagementLevel,
    CASE 
        WHEN STRING_AGG(CAST(b.Name AS varchar), ', ') IS NULL THEN 'No Badges'
        ELSE STRING_AGG(CAST(b.Name AS varchar), ', ') 
    END AS Badges
FROM UserPostInteraction upi
LEFT JOIN Badges b ON upi.UserId = b.UserId
GROUP BY upi.UserId, upi.DisplayName, upi.PostId, upi.Title, upi.EngagementLevel
ORDER BY upi.DisplayName, upi.PostId DESC;
