WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, CommentCount, VoteCount, ViewRank
    FROM 
        RankedPosts
    WHERE 
        ViewRank <= 5
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(tp.PostId) AS TotalPosts,
        SUM(tp.CommentCount) AS TotalComments,
        SUM(tp.VoteCount) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        TopPosts tp ON u.Id = tp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalComments,
    ups.TotalVotes
FROM 
    UserPostStats ups
WHERE 
    ups.TotalPosts > 0
ORDER BY 
    ups.TotalVotes DESC, ups.TotalComments DESC, ups.TotalPosts DESC
LIMIT 10;
