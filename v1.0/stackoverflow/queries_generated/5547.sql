WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rnk
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        rp.VoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rnk <= 5
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT tp.PostId) AS PostCount,
        SUM(tp.VoteCount) AS TotalVotes,
        SUM(tp.CommentCount) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        TopPosts tp ON tp.PostId IN (SELECT ID FROM Posts WHERE OwnerUserId = u.Id)
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ups.DisplayName,
    ups.PostCount,
    ups.TotalVotes,
    ups.TotalComments,
    COALESCE(b.Name, 'No Badge') AS BadgeName
FROM 
    UserPostStats ups
LEFT JOIN 
    Badges b ON b.UserId = ups.UserId AND b.Class = 1
ORDER BY 
    ups.TotalVotes DESC, ups.PostCount DESC;
