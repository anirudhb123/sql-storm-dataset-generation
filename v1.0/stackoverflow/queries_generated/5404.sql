WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- questions only
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Owner,
        CreationDate,
        Score,
        CommentCount,
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        ScoreRank <= 10
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(c.Id) AS TotalComments,
        COUNT(DISTINCT tp.PostId) AS PostsEngaged
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        TopPosts tp ON u.Id = tp.OwnerUserId
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    u.LastAccessDate,
    COALESCE(ue.Upvotes, 0) AS Upvotes,
    COALESCE(ue.Downvotes, 0) AS Downvotes,
    COALESCE(ue.TotalComments, 0) AS TotalComments,
    COALESCE(ue.PostsEngaged, 0) AS PostsEngaged
FROM 
    Users u
LEFT JOIN 
    UserEngagement ue ON u.Id = ue.UserId
WHERE 
    u.Reputation > 1000
ORDER BY 
    u.Reputation DESC;
