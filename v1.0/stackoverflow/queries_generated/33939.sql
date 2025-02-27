WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE()) 
        AND p.PostTypeId = 1 -- Only questions
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
PostComments AS (
    SELECT 
        c.Id AS CommentId,
        c.PostId,
        c.Text,
        c.UserId,
        c.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY c.PostId ORDER BY c.CreationDate DESC) AS CommentRank
    FROM 
        Comments c
)
SELECT 
    rp.Title,
    rp.Score,
    rp.ViewCount,
    ur.DisplayName,
    ur.Reputation,
    ur.BadgeCount,
    ur.GoldBadges,
    ur.SilverBadges,
    ur.BronzeBadges,
    STRING_AGG(pc.Text, '; ') AS RecentComments
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    UserReputation ur ON u.Id = ur.UserId
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId AND pc.CommentRank <= 3
WHERE 
    rp.PostRank = 1 -- Select the top post per user
GROUP BY 
    rp.Title, rp.Score, rp.ViewCount, ur.DisplayName, ur.Reputation, ur.BadgeCount, ur.GoldBadges, ur.SilverBadges, ur.BronzeBadges
ORDER BY 
    rp.Score DESC;

### Query Explanation
1. **CTE - RankedPosts**: This Common Table Expression (CTE) ranks questions posted in the last year for each user based on their score.
2. **CTE - UserReputation**: This CTE aggregates users' reputation and counts their badges classified into Gold, Silver, and Bronze.
3. **CTE - PostComments**: This CTE ranks comments for each post and allows retrieval of the most recent comments.
4. **Main Query**: It joins the results from `RankedPosts`, `UserReputation`, and `PostComments`, focusing on the top-ranked post for each user. It uses `STRING_AGG` to concatenate the last three comments of each post into a single string for better readability.
5. **Filtering & Grouping**: The main query filters to include only the top posts and groups by the desired columns to ensure a complete dataset.
6. **Ordering**: Results are ordered by post score to highlight the most engaging questions.
