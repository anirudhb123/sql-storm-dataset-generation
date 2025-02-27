WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, u.DisplayName
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id
),
TopEngagedUsers AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        ue.Upvotes,
        ue.Downvotes,
        ue.TotalPosts,
        ue.TotalComments,
        RANK() OVER(ORDER BY (ue.Upvotes - ue.Downvotes) DESC) AS EngagementRank
    FROM 
        UserEngagement ue
    WHERE 
        ue.TotalPosts > 0
)
SELECT 
    rp.PostId, 
    rp.Title, 
    rp.OwnerDisplayName, 
    rp.CreationDate, 
    rp.Score, 
    rp.ViewCount, 
    rp.CommentCount,
    tue.DisplayName AS TopUserDisplayName,
    tue.Upvotes AS TopUserUpvotes,
    tue.Downvotes AS TopUserDownvotes
FROM 
    RankedPosts rp
JOIN 
    TopEngagedUsers tue ON tue.UserId = rp.OwnerUserId
WHERE 
    rp.PostRank <= 5 -- Only selecting top 5 recent posts per user
ORDER BY 
    tue.Upvotes - tue.Downvotes DESC, 
    rp.CreationDate DESC;
