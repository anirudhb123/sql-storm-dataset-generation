WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.Score > 10 AND rp.AnswerCount > 5 THEN 'Highly Engaged'
            WHEN rp.Score <= 10 AND rp.Score > 0 THEN 'Moderately Engaged'
            ELSE 'Low Engagement'
        END AS EngagementLevel
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1 -- Latest post by user
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(f.PostId) AS TotalPosts,
        SUM(CASE WHEN f.EngagementLevel = 'Highly Engaged' THEN 1 ELSE 0 END) AS HighEngagementCount
    FROM 
        Users u
    LEFT JOIN 
        FilteredPosts f ON u.Id = f.OwnerUserId
    WHERE 
        u.Reputation > 100 -- Users with good reputation
    GROUP BY 
        u.Id,
        u.DisplayName
),
TopEngagedUsers AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        ue.TotalPosts,
        ue.HighEngagementCount,
        ROW_NUMBER() OVER (ORDER BY ue.HighEngagementCount DESC) AS EngagementRank
    FROM 
        UserEngagement ue
)
SELECT 
    t.UserId,
    t.DisplayName,
    t.TotalPosts,
    t.HighEngagementCount,
    COALESCE(NULLIF(t.HighEngagementCount, 0), -1) AS HighEngagementCountAdjusted,
    CASE 
        WHEN t.HighEngagementCount = 0 THEN 'No Engagement'
        WHEN t.HighEngagementCount >= 1 AND t.HighEngagementCount < 5 THEN 'Some Engagement'
        ELSE 'High Engagement'
    END AS EngagementStatus
FROM 
    TopEngagedUsers t
WHERE 
    t.EngagementRank <= 10 -- Top 10 Users by Engagement
ORDER BY 
    t.HighEngagementCount DESC;

-- Include a recursive query to fetch all posts related to top engaged users
WITH RECURSIVE UserPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        TopEngagedUsers te ON p.OwnerUserId = te.UserId

    UNION ALL

    SELECT 
        p.RelatedPostId,
        p2.Title,
        p2.OwnerUserId
    FROM 
        PostLinks p
    JOIN 
        Posts p2 ON p.RelatedPostId = p2.Id
    JOIN 
        UserPosts up ON p.PostId = up.PostId
)
SELECT DISTINCT 
    up.PostId,
    up.Title,
    u.DisplayName
FROM 
    UserPosts up
JOIN 
    Users u ON up.OwnerUserId = u.Id;
