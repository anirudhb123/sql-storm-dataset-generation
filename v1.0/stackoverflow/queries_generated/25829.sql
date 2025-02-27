WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),

PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        COALESCE(pa.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(com.TotalComments, 0) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(*) AS TotalAnswers
        FROM 
            Posts
        WHERE 
            PostTypeId = 2
        GROUP BY 
            ParentId
    ) pa ON p.Id = pa.ParentId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS TotalComments
        FROM 
            Comments
        GROUP BY 
            PostId
    ) com ON p.Id = com.PostId
    WHERE 
        p.PostTypeId = 1
),

UserPostStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        ps.PostId,
        ps.Title,
        ps.TotalAnswers,
        ps.TotalComments,
        ps.ViewCount
    FROM 
        UserStats us
    JOIN Posts p ON us.UserId = p.OwnerUserId
    JOIN PostStats ps ON p.Id = ps.PostId
)

SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.Reputation,
    ups.PostId,
    ups.Title,
    ups.TotalAnswers,
    ups.TotalComments,
    ups.ViewCount,
    CASE 
        WHEN ups.TotalAnswers > 0 THEN 'Active Contributor'
        WHEN ups.TotalComments > 0 THEN 'Engaged User'
        ELSE 'New User'
    END AS UserType,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    UserPostStats ups
LEFT JOIN Tags t ON t.Id = ANY(STRING_TO_ARRAY(ups.Tags, ',')::int[])
GROUP BY 
    ups.UserId, ups.DisplayName, ups.Reputation, ups.PostId, ups.Title, ups.TotalAnswers, ups.TotalComments, ups.ViewCount
ORDER BY 
    ups.Reputation DESC, ups.UserId;
