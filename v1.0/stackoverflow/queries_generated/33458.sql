WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.EmailHash,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.EmailHash
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        ur.DisplayName,
        ur.Reputation,
        ur.BadgeCount,
        RANK() OVER (ORDER BY rp.Score DESC, rp.ViewCount DESC) AS PopularityRank
    FROM 
        RecentPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    WHERE 
        rp.PostRank = 1
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
FinalResults AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.ViewCount,
        tp.CreationDate,
        tp.DisplayName,
        tp.Reputation,
        tp.BadgeCount,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        tp.PopularityRank
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostComments pc ON tp.PostId = pc.PostId
)
SELECT 
    f.PostId,
    f.Title,
    f.ViewCount,
    f.CreationDate,
    f.DisplayName,
    f.Reputation,
    f.BadgeCount,
    f.CommentCount,
    CASE 
        WHEN f.Reputation >= 1000 THEN 'High Reputation'
        WHEN f.Reputation BETWEEN 500 AND 999 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory,
    CASE 
        WHEN f.CommentCount > 10 THEN 'Active Discussion'
        ELSE 'Few Comments'
    END AS DiscussionLevel
FROM 
    FinalResults f
WHERE 
    f.PopularityRank <= 10
ORDER BY 
    f.PopularityRank;

This SQL query performs complex operations, including:
- CTEs to manage recent posts, user reputations with badge counts, and top posts based on scores.
- Usage of window functions for ranking posts and partitioning data by users.
- Outer joins to include comments per post and aggregate badge counts effectively. 
- The final selection utilizes CASE statements to categorize users based on reputation and posts based on comment activity, ensuring that the query pulls insightful metrics for performance benchmarking.
