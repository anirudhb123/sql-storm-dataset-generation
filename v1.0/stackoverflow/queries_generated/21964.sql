WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId IN (2, 5) THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.UserId = u.Id 
    GROUP BY 
        u.Id, u.DisplayName
), 
UserRanked AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotes,
        DownVotes,
        PostCount,
        LastPostDate,
        RANK() OVER (ORDER BY UpVotes - DownVotes DESC, LastPostDate DESC) AS UserRank
    FROM 
        UserActivity
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 DAY'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
)
SELECT 
    ur.DisplayName AS ActiveUser,
    ur.UserRank,
    COUNT(rp.PostId) AS RecentPostCount,
    SUM(rp.Score) AS TotalScore,
    AVG(CASE WHEN rp.CommentCount IS NULL THEN 0 ELSE rp.CommentCount END) AS AvgCommentsPerPost,
    STRING_AGG(DISTINCT rp.Title, ', ') AS RecentPostTitles,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = ur.UserId AND b.Class = 1) AS GoldBadges,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = ur.UserId AND b.Class = 2) AS SilverBadges
FROM 
    UserRanked ur
LEFT JOIN 
    RecentPosts rp ON ur.UserId = rp.Author
WHERE 
    ur.UserRank <= 10
GROUP BY 
    ur.DisplayName, ur.UserRank
ORDER BY 
    ur.UserRank;

This query demonstrates a complex analytical operation on the Stack Overflow schema, featuring Common Table Expressions (CTEs) for user activity and recent posts, leveraging window functions for ranking and partitioning, while providing rich aggregate metrics. The query also incorporates a conditional aggregation to handle potential NULL values, string aggregation for post titles, and subqueries to count badge achievements. All elements are designed to test performance by involving multiple joins, aggregations, and window calculations.
