
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(p.ViewCount) AS TotalViews,
        @rank := @rank + 1 AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId,
        (SELECT @rank := 0) r
    GROUP BY 
        u.Id, u.DisplayName
),

PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
),

ClosedQuestions AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate AS ClosedDate,
        GROUP_CONCAT(DISTINCT ctr.Name ORDER BY ctr.Name SEPARATOR ', ') AS CloseReason
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    LEFT JOIN 
        CloseReasonTypes ctr ON CAST(JSON_UNQUOTE(JSON_EXTRACT(ph.Comment, '$.ReasonId')) AS UNSIGNED) = ctr.Id
    GROUP BY 
        p.Id, p.Title, ph.CreationDate
)

SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    ua.TotalViews,
    ps.PostId,
    ps.Title AS PostTitle,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.TotalBounty,
    cq.ClosedDate,
    cq.CloseReason
FROM 
    UserActivity ua
LEFT JOIN 
    PostStats ps ON ua.UserId = ps.OwnerUserId
LEFT JOIN 
    ClosedQuestions cq ON ps.PostId = cq.PostId
WHERE 
    ua.TotalPosts > 0
ORDER BY 
    ua.Rank, ps.PostId
LIMIT 10 OFFSET 10;
