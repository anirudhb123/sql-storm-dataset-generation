WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS Author,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, Title, Score, CreationDate, Author, RankScore, CommentCount, 
        UpVoteCount, DownVoteCount
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 10
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(tp.CommentCount) AS TotalComments,
        SUM(tp.UpVoteCount) AS TotalUpVotes,
        SUM(tp.DownVoteCount) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        TopPosts tp ON u.Id = tp.Author
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    u.DisplayName,
    COALESCE(ue.TotalComments, 0) AS TotalComments,
    COALESCE(ue.TotalUpVotes, 0) AS TotalUpVotes,
    COALESCE(ue.TotalDownVotes, 0) AS TotalDownVotes,
    CASE 
        WHEN ue.TotalComments > 0 AND ue.TotalUpVotes > ue.TotalDownVotes THEN 'Engaged'
        WHEN ue.TotalComments = 0 AND ue.TotalUpVotes = 0 THEN 'Inactive'
        ELSE 'Moderately Engaged'
    END AS EngagementLevel
FROM 
    Users u
LEFT JOIN 
    UserEngagement ue ON u.Id = ue.UserId
WHERE 
    u.Reputation > 100
ORDER BY 
    ue.TotalComments DESC, ue.TotalUpVotes DESC;
