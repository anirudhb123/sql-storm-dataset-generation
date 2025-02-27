
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 100 
    GROUP BY 
        u.Id, u.DisplayName
), 
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        @row_number := IF(@prev_owner = p.OwnerUserId, @row_number + 1, 1) AS rn,
        @prev_owner := p.OwnerUserId
    FROM 
        Posts p, (SELECT @row_number := 0, @prev_owner := NULL) AS vars
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    ORDER BY 
        p.OwnerUserId, p.CreationDate DESC
), 
RecentPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.ViewCount,
        ps.AnswerCount,
        ua.DisplayName AS OwnerName,
        ua.TotalUpvotes,
        ua.TotalDownvotes
    FROM 
        PostStats ps
    JOIN 
        UserActivity ua ON ps.PostId = (SELECT Id FROM Posts WHERE OwnerUserId = ua.UserId LIMIT 1)
    WHERE 
        ps.rn = 1 
    AND 
        ps.Score > 0 
)
SELECT 
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    COALESCE(rp.TotalUpvotes - rp.TotalDownvotes, 0) AS NetVotes,
    CASE 
        WHEN rp.TotalUpvotes > 3 THEN 'Active User'
        WHEN rp.TotalDownvotes > 3 THEN 'Content Issues'
        ELSE 'Moderate User'
    END AS UserActivityStatus,
    GROUP_CONCAT(DISTINCT pt.Name SEPARATOR ', ') AS RelatedPostTypes
FROM 
    RecentPosts rp
LEFT JOIN 
    PostTypes pt ON pt.Id = (SELECT PostTypeId FROM Posts WHERE Id = rp.PostId LIMIT 1)
GROUP BY 
    rp.Title, rp.Score, rp.ViewCount, rp.AnswerCount, rp.TotalUpvotes, rp.TotalDownvotes
ORDER BY 
    NetVotes DESC, rp.ViewCount DESC
LIMIT 10;
