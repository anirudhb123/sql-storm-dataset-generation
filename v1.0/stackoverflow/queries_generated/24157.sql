WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(v.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(v.DownVotes, 0)) AS TotalDownVotes,
        RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS PostRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT 
            UserId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
          FROM 
            Votes 
          GROUP BY 
            UserId) v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        u.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        SUM(COALESCE(ph.Comment, 0)) AS HistoryCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (5, 6, 10) 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, u.DisplayName
)
SELECT 
    CASE 
        WHEN ua.PostCount IS NULL THEN 'No Posts'
        WHEN ua.TotalUpVotes IS NULL AND ua.TotalDownVotes IS NULL THEN 'No Votes'
        ELSE ua.DisplayName
    END AS UserDisplayName,
    ua.PostCount,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    tp.PostId,
    tp.Title AS TopPostTitle,
    tp.Score AS TopPostScore,
    tp.CommentCount AS TotalComments,
    tp.HistoryCount AS EditHistoryCount,
    COALESCE(tp.OwnerPostRank, 0) AS OwnerPostRank
FROM 
    UserActivity ua
FULL OUTER JOIN 
    TopPosts tp ON ua.UserId = tp.OwnerPostRank
WHERE 
    (ua.PostCount > 5 OR (tp.OwnerPostRank IS NOT NULL AND tp.Score > 10))
    AND (tp.CommentCount IS NULL OR tp.CommentCount < 5)
ORDER BY 
    ua.TotalUpVotes DESC, tp.Score DESC;

