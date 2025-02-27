
WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
), 
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(uc.UserCount, 0) AS UniqueCommentCount,
        COALESCE(uc.UserNames, 'None') AS CommentUserNames,
        @row_number := @row_number + 1 AS Rank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(DISTINCT UserId) AS UserCount,
            GROUP_CONCAT(DISTINCT UserDisplayName ORDER BY UserDisplayName SEPARATOR ', ') AS UserNames
        FROM 
            Comments
        GROUP BY 
            PostId
    ) uc ON p.Id = uc.PostId,
    (SELECT @row_number := 0) r
),
RankedPosts AS (
    SELECT 
        ps.*,
        @view_rank := @view_rank + 1 AS ViewRank
    FROM 
        PostStats ps,
    (SELECT @view_rank := 0) vr
    ORDER BY ps.ViewCount DESC
)
SELECT 
    uvs.UserId,
    uvs.DisplayName,
    p.Title AS PostTitle,
    p.ViewCount,
    p.UniqueCommentCount,
    p.CommentUserNames,
    CASE 
        WHEN p.Rank = 1 THEN 'Top Post'
        WHEN p.Rank <= 10 THEN 'Trending Post'
        ELSE 'Regular Post'
    END AS PostCategory,
    uvs.TotalUpVotes,
    uvs.TotalDownVotes
FROM 
    UserVoteStats uvs
JOIN 
    RankedPosts p ON uvs.UserId = p.PostId
WHERE 
    (uvs.TotalUpVotes + uvs.TotalDownVotes > 0)
    AND p.ViewCount > 50
ORDER BY 
    p.ViewCount DESC, 
    uvs.TotalUpVotes DESC
LIMIT 100;
