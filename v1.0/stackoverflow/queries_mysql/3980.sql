
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswer
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 30 DAY
        AND p.PostTypeId = 1
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        ue.UserId,
        ue.CommentCount,
        ue.TotalUpVotes,
        ue.TotalDownVotes,
        @row_number:=IF(@prev_user_id = ue.UserId, @row_number + 1, 1) AS UserRank,
        @prev_user_id := ue.UserId
    FROM 
        RecentPosts rp
    JOIN 
        UserEngagement ue ON ue.UserId = rp.AcceptedAnswer,
        (SELECT @row_number := 0, @prev_user_id := '') AS vars
)
SELECT 
    ps.Title,
    ps.ViewCount,
    tu.TotalComments,
    tu.TotalVotes,
    CASE 
        WHEN ps.UserRank = 1 THEN 'Top Post for User'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    PostStatistics ps
LEFT JOIN 
    (SELECT 
         UserId,
         SUM(CommentCount) AS TotalComments,
         SUM(TotalUpVotes) AS TotalVotes
     FROM 
         UserEngagement
     GROUP BY 
         UserId
     HAVING 
         SUM(CommentCount) > 5) tu ON ps.UserId = tu.UserId
WHERE 
    ps.ViewCount > 50
ORDER BY 
    ps.ViewCount DESC, 
    tu.TotalVotes DESC
LIMIT 10;
