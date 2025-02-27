WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '7 days'
        AND p.PostTypeId = 1  -- Questions only
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    GROUP BY 
        u.Id
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        v.PostId
)
SELECT 
    u.DisplayName,
    us.TotalQuestions,
    us.TotalScore,
    us.AvgViewCount,
    rp.Title,
    rp.ViewCount AS RecentViewCount,
    COALESCE(rv.VoteCount, 0) AS RecentVoteCount,
    COALESCE(rv.Upvotes, 0) AS UpvoteCount,
    COALESCE(rv.Downvotes, 0) AS DownvoteCount,
    CASE 
        WHEN us.TotalScore > 100 THEN 'High Score'
        WHEN us.TotalScore BETWEEN 50 AND 100 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    Users u
LEFT JOIN 
    UserStats us ON u.Id = us.UserId
LEFT JOIN 
    RankedPosts rp ON rp.OwnerUserId = u.Id AND rp.RowNum = 1
LEFT JOIN 
    RecentVotes rv ON rv.PostId = rp.PostId
WHERE 
    u.Reputation > 50
ORDER BY 
    us.TotalScore DESC, 
    rp.ViewCount DESC
LIMIT 10;

-- The SQL query above performs the following:
-- 1. It creates three common table expressions (CTEs) to rank posts, aggregate user stats, and calculate recent votes.
-- 2. It calculates the number of questions and total score per user.
-- 3. It retrieves the most recent question for each user who has a higher reputation score.
-- 4. It joins the vote statistics to show how many votes each user's most recent question received, including upvotes and downvotes.
-- 5. Finally, it categorizes users based on their score into 'High Score', 'Medium Score', and 'Low Score' before retrieving the most relevant records.
