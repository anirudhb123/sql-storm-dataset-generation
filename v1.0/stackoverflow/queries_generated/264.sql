WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        COUNT(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 END) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COALESCE(SUM(CASE WHEN c.Id IS NOT NULL THEN 1 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN ph.PostId IS NOT NULL THEN 1 END), 0) AS HistoryCount,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) as rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title, p.Score
),
RecentPosts AS (
    SELECT 
        ps.* 
    FROM 
        PostStatistics ps
    WHERE 
        ps.rn <= 100
),
VotingData AS (
    SELECT 
        p.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CommentCount,
    rp.HistoryCount,
    vd.TotalUpvotes,
    vd.TotalDownvotes,
    uvs.DisplayName,
    uvs.Upvotes,
    uvs.Downvotes,
    CASE 
        WHEN rp.Score > 10 THEN 'High' 
        WHEN rp.Score BETWEEN 1 AND 10 THEN 'Medium' 
        ELSE 'Low' 
    END AS PostScoreCategory
FROM 
    RecentPosts rp
LEFT JOIN 
    VotingData vd ON rp.PostId = vd.PostId
LEFT JOIN 
    UserVoteStats uvs ON uvs.TotalVotes = (SELECT MAX(TotalVotes) FROM UserVoteStats)
ORDER BY 
    rp.Score DESC, rp.PostId;
