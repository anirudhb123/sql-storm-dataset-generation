
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        @rank := @rank + 1 AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId,
        (SELECT @rank := 0) r
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) > 100  
),
RecentComments AS (
    SELECT 
        c.Id,
        c.PostId,
        c.UserDisplayName,
        c.Text,
        c.CreationDate,
        @comment_rank := IF(@current_post = c.PostId, @comment_rank + 1, 1) AS CommentRank,
        @current_post := c.PostId
    FROM 
        Comments c,
        (SELECT @current_post := 0, @comment_rank := 0) r
    ORDER BY 
        c.PostId, c.CreationDate DESC
)
SELECT 
    ph.PostId,
    ph.Title,
    u.UserId,
    u.DisplayName AS TopUserDisplayName,
    u.UpVotes,
    u.DownVotes,
    comments.UserDisplayName AS LastCommentUser,
    comments.Text AS LastCommentText
FROM 
    PostHierarchy ph
LEFT JOIN 
    TopUsers u ON ph.PostId IN (SELECT ParentId FROM Posts WHERE Id = ph.PostId)
LEFT JOIN 
    RecentComments comments ON ph.PostId = comments.PostId AND comments.CommentRank = 1
WHERE 
    ph.Level <= 3  
ORDER BY 
    ph.PostId;
