WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    WHERE 
        p.CreationDate >= '2020-01-01'
    GROUP BY 
        p.Id, p.Title, p.Score, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        (rp.UpVotes - rp.DownVotes) AS VoteBalance,
        rp.CommentCount,
        ub.BadgeCount,
        ub.HighestBadgeClass
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    WHERE 
        rp.Score > 0 AND rp.CommentCount > 5
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.Score,
    pp.VoteBalance,
    pp.CommentCount,
    ub.DisplayName AS OwnerName,
    ub.Reputation,
    (CASE 
        WHEN pp.HighestBadgeClass = 1 THEN 'Gold' 
        WHEN pp.HighestBadgeClass = 2 THEN 'Silver' 
        WHEN pp.HighestBadgeClass = 3 THEN 'Bronze'
        ELSE 'None' 
     END) AS HighestBadge
FROM 
    PopularPosts pp
JOIN 
    Users ub ON pp.OwnerUserId = ub.Id
WHERE 
    pp.BadgeCount > 0
    AND pp.CommentCount >= 10
ORDER BY 
    pp.VoteBalance DESC,
    pp.Score DESC
LIMIT 100;

This SQL query does the following:
1. It starts with a common table expression (CTE) called `RankedPosts` to rank posts by their creation date for each user and aggregate their details including scores and votes.
2. Then it creates another CTE called `UserBadges` to count how many badges each user has and identify their highest badge class.
3. Next, the `PopularPosts` CTE filters the ranked posts to identify posts that are popular based on certain criteria (positive score and numerous comments).
4. Finally, it selects the relevant data from `PopularPosts`, joining in the user details, and filtering by badge count and comments for a final output of popular posts limited to the top 100 results sorted by vote balance and score.
